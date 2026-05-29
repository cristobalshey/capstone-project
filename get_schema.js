const { createClient } = require('@supabase/supabase-js');
const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';
const supabase = createClient(url, serviceKey);

async function checkSchema() {
    const tables = ['profiles', 'user_projects', 'community_posts', 'user_activities', 'projects'];
    for (const table of tables) {
        const { data, error } = await supabase.from(table).select('*').limit(1);
        if (error) {
            console.log(`Error in ${table}:`, error.message);
        } else if (data && data.length > 0) {
            console.log(`Table ${table} columns:`, Object.keys(data[0]));
        } else {
            console.log(`Table ${table} is empty, could not determine columns.`);
        }
    }
}
checkSchema();
