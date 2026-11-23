
update public.reports report
set
  reporter_name = coalesce(nullif(user_profile.display_name, ''), user_profile.email),
  reporter_email = user_profile.email
from public.users user_profile
where user_profile.id = report.user_id
  and (report.reporter_name is null or report.reporter_name = '');
