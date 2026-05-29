// Shared helper to insert into public.user_projects
window.submitUserProject = async function ({ type = 'manual', project_id = null, submission_data = {}, points = 0, setCode = false }) {
  const { data: { user } } = await window.supabaseClient.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const payload = {
    user_id: user.id,
    type: type,
    status: 'pending',
    submission_date: new Date().toISOString(),
    submission_data: submission_data,
    points: points
  };
  if (project_id) payload.project_id = project_id;

  const { data: insertData, error: insertErr } = await window.supabaseClient
    .from('user_projects')
    .insert([payload])
    .select('id')
    .single();

  if (insertErr) return { error: insertErr };

  const newId = insertData?.id;
  if (setCode && type === 'manual' && newId) {
    try {
      const code = `MAN-${newId.split('-')[0].toUpperCase()}`;
      const description = (submission_data && submission_data.waste_name)
        ? `${submission_data.waste_name} · ${submission_data.weight || 0} kg`
        : null;

      const { error: updErr } = await window.supabaseClient
        .from('user_projects')
        .update({ code: code, description: description })
        .eq('id', newId);

      if (updErr) return { id: newId, error: updErr };
    } catch (e) {
      return { id: newId, error: e };
    }
  }

  return { id: newId };
};
