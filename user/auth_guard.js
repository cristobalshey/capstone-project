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

    const role = profile.role; // 'resident', 'collector', 'moderator', 'admin'
    window.currentUserProfile = profile; // Store full profile
    window.currentPassCode = profile.pass_code; // Store for sensitive actions
    window.currentPinCode = profile.pin_code; // Store for PIN actions
    window.currentStatus = profile.status; // 'verified', 'pending', 'banned', etc.
    const isAdmin = role === 'admin' || role === 'moderator';

    // 2.5 Check for Terms Acceptance (Skip for Admin)
    const isTermsPage = currentPath.includes('accept_terms.html');
    const isPasswordPage = currentPath.includes('set_password.html');
    const isPinPage = currentPath.includes('set_pin.html');

    if (!isAdmin && !profile.accepted_terms && !isTermsPage) {
        window.location.href = 'accept_terms.html';
        return;
    }

    // 2.6 Check for PIN Setup (Skip for Admin)
    if (!isAdmin && (profile.has_pin === false || profile.has_pin === null || profile.has_pin === undefined) && !isPinPage && !isTermsPage) {
        window.location.href = 'set_pin.html';
        return;
    }

    // 2.7 Check for First-Time Password (Skip for Admin)
    if (!isAdmin && (profile.has_password === false || profile.has_password === null || profile.has_password === undefined) && !isPasswordPage && !isPinPage && !isTermsPage) {
        window.location.href = 'set_password.html';
        return;
    }

    // 3. Define Protection Logic
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
            window.location.href = 'menu.html?error=unverified';
            return;
        }

        if (isAdminPath || isCollectorPath) {
            alert("Unauthorized Access: You do not have permission to view this section.");
            window.location.href = 'menu.html';
        }
    } 
    else if (role === 'collector') {
        if (isAdminPath || isUserPath) {
            alert("Unauthorized Access: Collectors cannot access admin or user sections.");
            window.location.href = '../collector/collector_dashboard.html';
        }
    }
    else if (role === 'admin' || role === 'moderator') {
        // Admins and Moderators have full access to all sections.
        // No restrictions needed here.
    }

}

function redirectToLogin(path) {
    if (path.includes('/admin/')) window.location.href = '../admin/index.html';
    else if (path.includes('/collector/')) window.location.href = '../collector/index.html';
    else window.location.href = 'login.html';
}

// Run the check on load
document.addEventListener('DOMContentLoaded', checkAccess);
