const profiles = [
  { id: '503c...', role: 'admin', status: 'new', address: null },
  { id: '5cdf...', role: 'resident', status: 'verified', address: '#521, Purok 4, Lagundi, Plaridel, Bulacan' },
  { id: '9f4f...', role: 'resident', status: 'verified', address: 'Lagundi, Paridel, Bulacan' },
  { id: 'aade...', role: 'collector', status: 'verified', address: 'Lagundi, Paridel, Bulacan' }
];

const userProjects = [
  { type: 'mission', status: 'pending', description: null, user_id: '9f4f...', project_id: '684f...', points: 551 },
  { type: 'quiz', status: 'approved', description: null, user_id: '9f4f...', project_id: '4154...', points: 30 },
  { type: 'manual', status: 'pending', description: 'Corrugated Cardboard · 1 kg', user_id: '9f4f...', project_id: null, points: 33 }
];

const projects = [
  { id: 'e10c...', type: 'Game', target_weight: null },
  { id: '4154...', type: 'Quiz', target_weight: null },
  { id: '684f...', type: 'Mission', target_weight: 1.00 }
];

let totalWaste = 0;
userProjects.forEach(up => {
    const upType = (up.type || '').toLowerCase();
    
    // I will test with 'pending' to see if it parses correctly
    if (upType === 'mission' && (up.status === 'completed' || up.status === 'pending')) {
        const proj = projects.find(p => p.id === up.project_id);
        if (proj && proj.target_weight) {
            totalWaste += Number(proj.target_weight);
        }
    } else if (upType === 'manual' && (up.status === 'approved' || up.status === 'pending')) {
        if (up.description) {
            const match = up.description.match(/(\d+(\.\d+)?)\s*kg/i);
            if (match && match[1]) {
                totalWaste += Number(match[1]);
            }
        }
    }
});
console.log('Total Waste:', totalWaste);

const purokTasks = {
    "Purok 1": 0, "Purok 2": 0, "Purok 3": 0, 
    "Purok 4": 0, "Purok 5": 0, "Purok 6": 0, "Purok 7": 0
};
const validProjects = userProjects.filter(up => ['approved', 'completed', 'pending'].includes(up.status));

validProjects.forEach(up => {
    const user = profiles.find(p => p.id === up.user_id);
    if (user && user.address) {
        const match = user.address.match(/purok\s*([1-7])\b/i);
        if (match) {
            const purokName = `Purok ${match[1]}`;
            purokTasks[purokName] = (purokTasks[purokName] || 0) + 1;
        }
    }
});
console.log('Purok Tasks:', purokTasks);
