/**
 * EcoTrack - Role-Based Access Control (RBAC) Guard
 * This script ensures that users can only access folders matching their role.
 */

async function checkAccess() {
    const { data: { session } } = await window.supabaseClient.auth.getSession();
    const currentPath = window.location.pathname;

    // 1. If no session, send to login (unless already on a login/signup page)
    if (!session) {
        if (!currentPath.includes('login.html') && !currentPath.includes('signup.html') && !currentPath.endsWith('/') && !currentPath.endsWith('index.html')) {
            redirectToLogin(currentPath);
        }
        return;
    }

    // 2. Fetch User Profile & Role
    const { data: profile, error } = await window.supabaseClient
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single();

    if (error || !profile) {
        console.error("Error fetching profile role:", error);
        return;
    }

    // 2.1 Handle Soft-Deleted Profile Reset (Go back to new user)
    if (profile.deleted === true) {
        console.log("Deleted profile detected. Resetting to new user state...");
        const success = await resetProfileToNewUser(
            session.user.id,
            session.user.email,
            session.user.user_metadata?.full_name
        );
        if (success) {
            window.location.reload();
            return;
        }
    }

    const role = profile.role; // 'resident', 'collector', 'moderator', 'admin'
    window.currentUserProfile = profile; // Store full profile
    window.currentPassCode = profile.pass_code; // Store for sensitive actions
    window.currentPinCode = profile.pin_code; // Store for PIN actions
    window.currentStatus = profile.status; // 'verified', 'pending', 'banned', etc.
    const normalizedRole = role ? role.toString().toLowerCase().trim() : '';
    const isAdmin = normalizedRole === 'admin' || normalizedRole === 'moderator';
    const isCollectorStaff = normalizedRole.includes('collector');

    // 2.5 Check for Terms Acceptance (Skip for Admin)
    const isTermsPage = currentPath.includes('accept_terms.html');
    const isPasswordPage = currentPath.includes('set_password.html');
    const isPinPage = currentPath.includes('set_pin.html');

    if (!isAdmin && !profile.accepted_terms && !isTermsPage) {
        window.location.href = '../user/accept_terms.html';
        return;
    }

    // 2.6 Check for PIN Setup (Skip for Admin or collector staff)
    if (!isAdmin && !isCollectorStaff && (profile.has_pin === false || profile.has_pin === null || profile.has_pin === undefined) && !isPinPage && !isTermsPage) {
        window.location.href = '../user/set_pin.html';
        return;
    }

    // 2.7 Check for First-Time Password (Skip for Admin or collector staff)
    if (!isAdmin && !isCollectorStaff && (profile.has_password === false || profile.has_password === null || profile.has_password === undefined) && !isPasswordPage && !isPinPage && !isTermsPage) {
        window.location.href = '../user/set_password.html';
        return;
    }

    // 3. Collector approval gate
    const isCollectorProfilePage = currentPath.includes('/collector/collector_profile.html');
    const isCollectorVerificationPage = currentPath.includes('/collector/verification.html');
    const isCollectorAllowedPendingPage = isCollectorProfilePage || isCollectorVerificationPage;

    if (normalizedRole.includes('collector') && profile.status !== 'verified' && !isCollectorAllowedPendingPage) {
        window.location.href = '../collector/verification.html';
        return;
    }

    // 4. Define Protection Logic
    // Folder paths
    const isAdminPath = currentPath.includes('/admin/');
    const isCollectorPath = currentPath.includes('/collector/');
    const isUserPath = currentPath.includes('/user/');

    // Restricted Pages for Unverified Users
    const isRestrictedPage = currentPath.includes('mission.html') || 
                             currentPath.includes('quizzes.html') || 
                             currentPath.includes('manual.html') || 
                             currentPath.includes('character.html');

    // Access Rules
    if (role === 'resident' || role === 'user') {
        // Verification Check for Residents
        if (isRestrictedPage && profile.status !== 'verified') {
            window.location.href = '../user/menu.html?error=unverified';
            return;
        }

        if (isAdminPath || isCollectorPath) {
            alert("Unauthorized Access: You do not have permission to view this section.");
            window.location.href = '../user/menu.html';
        }
    } 
    else if (role === 'collector') {
        // Allow collectors to access user-facing pages but restrict access to admin pages only
        if (isAdminPath) {
            alert("Unauthorized Access: Collectors cannot access admin sections.");
            window.location.href = '../collector/collector_dashboard.html';
            return;
        }
    }
    else if (role === 'admin' || role === 'moderator') {
        // Admins and moderators are allowed to access both admin and user sections.
        // No restriction should prevent them from browsing user pages.
    }

    // 4. Initialize Realtime Notifications
    setupRealtimeNotifications(session.user.id);
}

async function resetProfileToNewUser(userId, email, fullName) {
    try {
        // 1. Reset profiles table row to defaults
        const { error: profileError } = await window.supabaseClient
            .from('profiles')
            .update({
                deleted: false,
                accepted_terms: false,
                has_pin: false,
                pin_code: null,
                has_password: false,
                pass_code: null,
                status: 'pending',
                points: 0,
                role: 'resident',
                full_name: fullName || 'Resident',
                dob: null,
                address: null,
                contact_number: null,
                id_type: null,
                id_image_url: null,
                selfie_image_url: null
            })
            .eq('id', userId);

        if (profileError) {
            console.error("Error resetting profile table:", profileError);
            return false;
        }

        // 2. Delete user_projects rows
        const { error: projectsError } = await window.supabaseClient
            .from('user_projects')
            .delete()
            .eq('user_id', userId);

        if (projectsError) {
            console.warn("Could not delete user_projects records (might be RLS policy):", projectsError);
        }

        // 3. Delete redemptions rows
        const { error: redemptionsError } = await window.supabaseClient
            .from('redemptions')
            .delete()
            .eq('user_id', userId);

        if (redemptionsError) {
            console.warn("Could not delete redemptions records (might be RLS policy):", redemptionsError);
        }

        return true;
    } catch (e) {
        console.error("Exception during profile reset:", e);
        return false;
    }
}

let isRealtimeSetup = false;

function setupRealtimeNotifications(userId) {
    if (isRealtimeSetup) return;
    isRealtimeSetup = true;

    if (!window.supabaseClient) return;

    // Request desktop notification permission
    if ('Notification' in window && Notification.permission === 'default') {
        Notification.requestPermission();
    }

    console.log("Setting up realtime notifications listener for user:", userId);

    window.supabaseClient
        .channel('public:notifications')
        .on('postgres_changes', {
            event: 'INSERT',
            schema: 'public',
            table: 'notifications'
        }, (payload) => {
            const notif = payload.new;
            console.log("New notification received:", notif);
            
            if (notif.user_id === null || notif.user_id === userId) {
                // 1. Play chime sound
                playNotificationSound();

                // 2. Show native browser desktop alert
                showBrowserNotification(notif.title, notif.description, notif.type);

                // 3. Show in-app SweetAlert toast alert
                showInAppToast(notif);
                
                // 4. Update the red dot badge dynamically if we are on menu.html
                if (typeof updateNotifBadge === 'function') {
                    updateNotifBadge();
                }
            }
        })
        .subscribe((status) => {
            console.log("Realtime subscription status:", status);
        });
}

function showBrowserNotification(title, body, type) {
    if ('Notification' in window && Notification.permission === 'granted') {
        try {
            const notifInstance = new Notification(title, {
                body: body,
                icon: window.location.origin + '/user/image/logo.png'
            });
            notifInstance.onclick = () => {
                window.focus();
                
                const currentPath = window.location.pathname;
                let destination = '';
                if (currentPath.includes('/admin/')) {
                    destination = '../admin/admin_projects_hub.html';
                } else if (currentPath.includes('/collector/')) {
                    destination = '../collector/collector_dashboard.html';
                } else {
                    if (type === 'Mission') {
                        destination = 'mission.html';
                    } else if (type === 'Quiz') {
                        destination = 'quizzes.html';
                    } else if (type === 'Reward') {
                        destination = 'redeem.html';
                    } else {
                        destination = 'notification.html';
                    }
                }
                window.location.href = destination;
            };
        } catch (err) {
            console.error("Browser notification failed:", err);
        }
    }
}

function showInAppToast(notif) {
    if (typeof Swal !== 'undefined') {
        Swal.fire({
            title: notif.title,
            text: notif.description,
            icon: 'info',
            toast: true,
            position: 'top-end',
            showConfirmButton: false,
            timer: 5000,
            timerProgressBar: true,
            didOpen: (toast) => {
                toast.addEventListener('mouseenter', Swal.stopTimer);
                toast.addEventListener('mouseleave', Swal.resumeTimer);
                toast.addEventListener('click', () => {
                    const currentPath = window.location.pathname;
                    let destination = '';
                    if (currentPath.includes('/admin/')) {
                        destination = '../admin/admin_projects_hub.html';
                    } else if (currentPath.includes('/collector/')) {
                        destination = '../collector/collector_dashboard.html';
                    } else {
                        if (notif.type === 'Mission') {
                            destination = 'mission.html';
                        } else if (notif.type === 'Quiz') {
                            destination = 'quizzes.html';
                        } else if (notif.type === 'Reward') {
                            destination = 'redeem.html';
                        } else {
                            destination = 'notification.html';
                        }
                    }
                    window.location.href = destination;
                });
            }
        });
    }
}

function playNotificationSound() {
    try {
        const AudioContextClass = window.AudioContext || window.webkitAudioContext;
        if (!AudioContextClass) return;
        const context = new AudioContextClass();
        const osc = context.createOscillator();
        const gain = context.createGain();
        osc.connect(gain);
        gain.connect(context.destination);
        
        osc.type = 'sine';
        osc.frequency.setValueAtTime(587.33, context.currentTime); // D5
        osc.frequency.setValueAtTime(880.00, context.currentTime + 0.1); // A5
        
        gain.gain.setValueAtTime(0.08, context.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.35);
        
        osc.start();
        osc.stop(context.currentTime + 0.35);
    } catch (e) {
        console.warn("Could not play notification sound:", e);
    }
}

function redirectToLogin(path) {
    if (path.includes('/admin/')) window.location.href = '../admin/index.html';
    else if (path.includes('/collector/')) window.location.href = '../collector/index.html';
    else window.location.href = '../user/login.html';
}

// Run the check on load
document.addEventListener('DOMContentLoaded', checkAccess);
