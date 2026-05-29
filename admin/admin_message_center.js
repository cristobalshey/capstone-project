// Admin Message Center Logic
let currentTab = 'pending_human';
let tickets = [];
let currentTicketId = null;
let adminSession = null;
let subscription = null;
let activeTicketSub = null;
let adminProfileId = null; // The ID of the profile with role='admin' from the profiles table

document.addEventListener('DOMContentLoaded', async () => {
    // 1. Get Admin Session
    const { data: { session } } = await window.supabaseClient.auth.getSession();
    if (!session) {
        window.location.href = 'login.html';
        return;
    }
    adminSession = session;

    // 2. Fetch the admin profile ID from the profiles table (role = 'admin')
    const { data: adminProfile } = await window.supabaseClient
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .limit(1)
        .single();

    if (adminProfile) {
        adminProfileId = adminProfile.id;
    } else {
        // Fallback to the logged-in session user ID if no admin profile found
        adminProfileId = session.user.id;
        console.warn('No profile with role="admin" found, falling back to session user ID.');
    }

    // 3. Initial Fetch
    await fetchTickets();

    // 4. Subscribe to ticket changes
    subscription = window.supabaseClient
        .channel('support_tickets_changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'support_tickets' }, payload => {
            fetchTickets(); // Refresh list on change
        })
        .subscribe();
});

// Tab Switching
window.switchTab = async (status) => {
    currentTab = status;
    document.getElementById('tab-pending').classList.toggle('active', status === 'pending_human');
    document.getElementById('tab-active').classList.toggle('active', status === 'active');
    
    currentTicketId = null;
    hideChat();
    await fetchTickets();
};

async function fetchTickets() {
    let query = window.supabaseClient
        .from('support_tickets')
        .select(`
            *,
            users:user_id (id, full_name)
        `)
        .order('created_at', { ascending: false });

    if (currentTab === 'pending_human') {
        query = query.eq('status', 'pending_human');
    } else if (currentTab === 'active') {
        query = query.eq('status', 'active').eq('assigned_admin_id', adminSession.user.id);
    }

    const { data, error } = await query;
    if (error) {
        console.error('Error fetching tickets:', error);
        return;
    }

    // fallback if users join fails
    if(data) {
        // We'll also fetch profile names if they don't join automatically
        const userIds = data.map(t => t.user_id);
        if(userIds.length > 0) {
            const { data: profiles } = await window.supabaseClient.from('profiles').select('id, full_name').in('id', userIds);
            
            data.forEach(t => {
                const profile = profiles?.find(p => p.id === t.user_id);
                t.user_name = profile?.full_name || 'Unknown User';
            });
        }
    }

    tickets = data || [];
    renderQueueList();
}

function renderQueueList() {
    const list = document.getElementById('queueList');
    list.innerHTML = '';

    if (tickets.length === 0) {
        list.innerHTML = `<div style="padding: 20px; text-align: center; color: #6b7280; font-size: 14px;">No ${currentTab === 'pending_human' ? 'pending' : 'active'} tickets found.</div>`;
        return;
    }

    tickets.forEach(ticket => {
        const div = document.createElement('div');
        div.className = `ticket-card ${ticket.id === currentTicketId ? 'active' : ''}`;
        div.onclick = () => selectTicket(ticket.id);

        const d = new Date(ticket.created_at);
        const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        div.innerHTML = `
            <div class="ticket-header">
                <span class="ticket-user">${ticket.user_name}</span>
                <span class="ticket-time">${timeStr}</span>
            </div>
            <span class="ticket-status ${ticket.status === 'pending_human' ? 'status-pending' : 'status-active'}">
                ${ticket.status === 'pending_human' ? 'Pending Human' : 'Active'}
            </span>
        `;
        list.appendChild(div);
    });
}

window.selectTicket = async (id) => {
    currentTicketId = id;
    renderQueueList(); // to update active class

    const ticket = tickets.find(t => t.id === id);
    if (!ticket) return;

    showChat();
    document.getElementById('chatUserName').textContent = ticket.user_name;
    
    // Setup UI based on status
    const isPending = ticket.status === 'pending_human';
    document.getElementById('claimBtn').style.display = isPending ? 'block' : 'none';
    document.getElementById('endChatBtn').style.display = isPending ? 'none' : 'block';
    document.getElementById('chatInput').disabled = isPending;
    document.getElementById('sendBtn').disabled = isPending;

    // Load Messages
    await loadMessages();
    subscribeToActiveTicket();
};

async function loadMessages() {
    const list = document.getElementById('chatMessages');
    list.innerHTML = '<div>Loading...</div>';

    const { data: messages } = await window.supabaseClient
        .from('direct_messages')
        .select('*')
        .eq('ticket_id', currentTicketId)
        .order('created_at', { ascending: true });

    list.innerHTML = '';
    if (messages) {
        messages.forEach(msg => {
            const type = msg.sender_id === '00000000-0000-0000-0000-000000000000' ? 'bot' : 
                         (msg.sender_id === adminProfileId || msg.sender_id === adminSession.user.id ? 'admin' : 'user');
            appendMessage(type, msg.content, msg.created_at);
        });
    }
    list.scrollTop = list.scrollHeight;
}

function subscribeToActiveTicket() {
    if (activeTicketSub) window.supabaseClient.removeChannel(activeTicketSub);

    activeTicketSub = window.supabaseClient
        .channel(`active_ticket_${currentTicketId}`)
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'direct_messages', filter: `ticket_id=eq.${currentTicketId}` }, payload => {
            const msg = payload.new;
            if (msg.sender_id !== adminProfileId && msg.sender_id !== adminSession.user.id) {
                const type = msg.sender_id === '00000000-0000-0000-0000-000000000000' ? 'bot' : 'user';
                appendMessage(type, msg.content, msg.created_at);
            }
        })
        .subscribe();
}

window.claimTicket = async () => {
    if (!currentTicketId) return;
    
    const { error } = await window.supabaseClient
        .from('support_tickets')
        .update({ 
            status: 'active', 
            assigned_admin_id: adminSession.user.id 
        })
        .eq('id', currentTicketId);
        
    if (!error) {
        // Automatically switch to Active tab
        await switchTab('active');
        // And select the ticket again
        selectTicket(currentTicketId);
    } else {
        console.error('Failed to claim ticket:', error);
    }
};

window.endChat = async () => {
    if (!currentTicketId) return;
    
    // 1. Mark as resolved and unassign the admin so the ticket expires cleanly
    const { error } = await window.supabaseClient
        .from('support_tickets')
        .update({ status: 'resolved', assigned_admin_id: null })
        .eq('id', currentTicketId);
        
    if (!error) {
        const ticket = tickets.find(t => t.id === currentTicketId);
        // 2. Send a final closing message
        await window.supabaseClient.from('direct_messages').insert({
            sender_id: adminProfileId,
            receiver_id: ticket.user_id,
            sender_name: 'Admin',
            receiver_name: ticket.user_name,
            content: 'The admin has ended this conversation. If you need more help, feel free to send a new message!',
            ticket_id: currentTicketId
        });
        
        // 3. Clear UI
        hideChat();
        await fetchTickets();
    } else {
        console.error('Failed to end chat:', error);
    }
};

window.sendMessage = async () => {
    const input = document.getElementById('chatInput');
    const content = input.value.trim();
    if (!content || !currentTicketId) return;

    input.value = '';
    appendMessage('admin', content);

    const ticket = tickets.find(t => t.id === currentTicketId);

    await window.supabaseClient.from('direct_messages').insert({
        sender_id: adminProfileId, // Use the admin role profile ID from the profiles table
        receiver_id: ticket.user_id, // Important for the user to get it
        sender_name: 'Admin',
        receiver_name: ticket.user_name,
        content: content,
        ticket_id: currentTicketId
    });
};

document.getElementById('chatInput').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') sendMessage();
});

function appendMessage(type, text, time = new Date().toISOString()) {
    const list = document.getElementById('chatMessages');
    const div = document.createElement('div');
    div.className = `message ${type}`;
    
    const d = new Date(time);
    const timeStr = d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    
    div.innerHTML = `
        <div>${text}</div>
        <div class="message-meta">${timeStr}</div>
    `;
    list.appendChild(div);
    list.scrollTop = list.scrollHeight;
}

function showChat() {
    document.getElementById('emptyState').style.display = 'none';
    document.getElementById('chatArea').style.display = 'flex';
}

function hideChat() {
    document.getElementById('emptyState').style.display = 'flex';
    document.getElementById('chatArea').style.display = 'none';
    if (activeTicketSub) {
        window.supabaseClient.removeChannel(activeTicketSub);
        activeTicketSub = null;
    }
}
