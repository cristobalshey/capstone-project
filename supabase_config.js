// Supabase Configuration
const supabaseUrl = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NzI4MDEsImV4cCI6MjA5MzQ0ODgwMX0.1YSPPaA__h6H8rK6FZqlUf6brxskMAEY2NYoERqKYgw'; 

// Safe storage wrapper: some browsers block access to localStorage
// (tracking protection). Provide a no-op fallback to avoid errors.
function safeStorage() {
	try {
		const key = '__st_test__';
		localStorage.setItem(key, key);
		localStorage.removeItem(key);
		return {
			getItem: k => localStorage.getItem(k),
			setItem: (k, v) => localStorage.setItem(k, v),
			removeItem: k => localStorage.removeItem(k)
		};
	} catch (e) {
		return {
			getItem: () => null,
			setItem: () => {},
			removeItem: () => {}
		};
	}
}

// Create Supabase client with conservative auth options to avoid
// automatic background refresh attempts when the browser is offline.
// Use the safe storage wrapper so tracking prevention doesn't throw.
const _supabase = supabase.createClient(supabaseUrl, supabaseKey, {
	auth: {
		autoRefreshToken: false,
		persistSession: true,
		storage: safeStorage()
	}
});

// Export for use in other scripts
window.supabaseClient = _supabase;

// Helpful log for debugging initialization issues
try {
	console.info('Supabase client initialized');
} catch (e) {
	console.error('Supabase init error:', e);
}

// Controlled refresh helper: attempts to refresh token only when online and
// when the page is visible. This avoids background refresh errors when offline.
async function safeRefreshSession() {
	if (!navigator.onLine) return; // don't try when offline
	if (document.hidden) return; // avoid refreshing while in background

	try {
		const session = _supabase.auth.getSession();
		// Only refresh if a refresh token exists in the session
		const stored = await _supabase.auth.getSession();
		if (stored && stored.data && stored.data.session && stored.data.session.refresh_token) {
			// call refresh via signInWithRefreshToken (v2 SDK might expose different methods)
			await _supabase.auth.refreshSession();
			console.info('Supabase session refreshed safely');
		}
	} catch (err) {
		console.warn('Safe refresh failed (likely offline):', err?.message || err);
	}
}

// Wire visibility and online events to attempt refresh when appropriate
window.addEventListener('online', () => safeRefreshSession());
document.addEventListener('visibilitychange', () => {
	if (!document.hidden) safeRefreshSession();
});

// Expose helper for manual refresh
window.safeRefreshSession = safeRefreshSession;
