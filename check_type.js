
const { createClient } = require('@supabase/supabase-js');
const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';
const supabase = createClient(url, serviceKey);

async function checkScoreType() {
    // We can't easily check column types via standard select, but we can try to insert a float and see if it fails
    // Or we can query the information_schema if we have permissions
    const { data, error } = await supabase.rpc('get_column_type', { table_name: 'user_projects', column_name: 'score' });
    if (error) {
        // Fallback: try to query the schema directly via SQL if possible
        const { data: cols, error: err2 } = await supabase.from('user_projects').select('score').limit(1);
        console.log("Current score value example:", cols?.[0]?.score);
    } else {
        console.log("Column type:", data);
    }
}
checkScoreType();
