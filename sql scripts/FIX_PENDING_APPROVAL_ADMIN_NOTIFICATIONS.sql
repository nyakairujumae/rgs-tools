-- Create admin notification when a pending_user_approvals row is inserted
-- Safe, additive change: no deletes, no data changes.

CREATE OR REPLACE FUNCTION public.notify_admin_on_pending_user_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'pending' THEN
    IF NOT EXISTS (
      SELECT 1
      FROM admin_notifications
      WHERE type = 'new_registration'
        AND (data->>'user_id') = NEW.user_id::TEXT
    ) THEN
      IF to_regprocedure('public.create_admin_notification(text,text,text,text,text,jsonb)') IS NOT NULL THEN
        PERFORM public.create_admin_notification(
          'New User Registration',
          COALESCE(NEW.full_name, NEW.email) || ' has registered and is waiting for approval',
          COALESCE(NEW.full_name, NEW.email),
          NEW.email,
          'new_registration',
          jsonb_build_object(
            'user_id', NEW.user_id,
            'email', NEW.email,
            'submitted_at', NEW.submitted_at
          )
        );
      ELSE
        INSERT INTO admin_notifications (
          title,
          message,
          technician_name,
          technician_email,
          type,
          is_read,
          timestamp,
          data
        ) VALUES (
          'New User Registration',
          COALESCE(NEW.full_name, NEW.email) || ' has registered and is waiting for approval',
          COALESCE(NEW.full_name, NEW.email),
          NEW.email,
          'new_registration',
          false,
          NOW(),
          jsonb_build_object(
            'user_id', NEW.user_id,
            'email', NEW.email,
            'submitted_at', NEW.submitted_at
          )
        );
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_pending_user_approval_notify_admin
ON public.pending_user_approvals;

CREATE TRIGGER on_pending_user_approval_notify_admin
AFTER INSERT ON public.pending_user_approvals
FOR EACH ROW
EXECUTE FUNCTION public.notify_admin_on_pending_user_approval();
