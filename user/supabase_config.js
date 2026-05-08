// Supabase Configuration
const supabaseUrl = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc4NzI4MDEsImV4cCI6MjA5MzQ0ODgwMX0.1YSPPaA__h6H8rK6FZqlUf6brxskMAEY2NYoERqKYgw'; 

const _supabase = supabase.createClient(supabaseUrl, supabaseKey);

// Export for use in other scripts
window.supabaseClient = _supabase;
