const { createClient } = require('@supabase/supabase-js');
const url = 'https://bstltlhrpxhrlvzzbpff.supabase.co';
const serviceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJzdGx0bGhycHhocmx2enpicGZmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3Nzg3MjgwMSwiZXhwIjoyMDkzNDQ4ODAxfQ.Bht8giQ2a8T5cUo3_ypOXMR_KJ8WSYLIwikwJKToGno';
const supabase = createClient(url, serviceKey);

async function fixData() {
    // 1. Update mission to 'completed'
    await supabase.from('user_projects').update({ status: 'completed' }).eq('type', 'mission');
    
    // 2. Update manual to 'approved'
    await supabase.from('user_projects').update({ status: 'approved' }).eq('type', 'manual');
    
    // 3. Update profile for the user to have a Purok
    await supabase.from('profiles').update({ address: 'Purok 1, Lagundi, Plaridel, Bulacan' }).eq('id', '9f4f6829-bccc-4308-8fec-7d9053103fd9');
    
    console.log("Data updated!");
}
fixData();
