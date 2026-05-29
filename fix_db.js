
const { createClient } = require('@supabase/supabase-js');

const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';

const supabase = createClient(url, serviceKey);

async function fixIds() {
    console.log("Fixing IDs...");
    
    // Fix Quiz ID
    const { error: error1 } = await supabase
        .from('user_projects')
        .update({ project_id: '4684911d-4dda-41ea-8cf2-8e3c5b7c68b9' })
        .eq('project_id', '4684911d-4dda-41ea-8cf2-8e3c5b567990');
    
    if (error1) console.error("Error fixing Quiz ID:", error1);
    else console.log("Quiz ID fixed.");

    // Fix Mission ID
    const { error: error2 } = await supabase
        .from('user_projects')
        .update({ project_id: 'c19517a7-266e-42b3-8533-df75aba9bccb' })
        .eq('project_id', 'c19517a7-266e-42b3-8533-df75ab6027a4');
    
    if (error2) console.error("Error fixing Mission ID:", error2);
    else console.log("Mission ID fixed.");
}

fixIds();
