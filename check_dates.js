const { createClient } = require('@supabase/supabase-js');
const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';
const supabase = createClient(url, serviceKey);

async function checkDates() {
    let res = await supabase.from('user_projects').select('submission_date, created_at').limit(5);
    console.log('user_projects dates:', res.data, res.error ? res.error.message : '');
}
checkDates();
