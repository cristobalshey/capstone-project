const { createClient } = require('@supabase/supabase-js');
const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';
const supabase = createClient(url, serviceKey);

async function checkProjects() {
    let res = await supabase.from('projects').select('id, type, waste_type, target_weight').limit(5);
    console.log('projects:', res.data);

    let res2 = await supabase.from('user_projects').select('id, project_id, score, points, type').limit(5);
    console.log('user_projects:', res2.data);
    
    // Check if score is the weight, or maybe projects target_weight is used
}
checkProjects();
