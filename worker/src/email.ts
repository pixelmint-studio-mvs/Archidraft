// Email service for Archi Draft registration and notifications
// Dispatches structured emails and persists audit trail in email_logs and notifications table.

export interface EmailDispatchOptions {
  to: string;
  name: string;
  subject: string;
  templateType: 'REGISTRATION_RECEIVED' | 'REGISTRATION_APPROVED' | 'REGISTRATION_REJECTED' | 'GENERAL_NOTIFICATION';
  textBody: string;
  htmlBody?: string;
}

export async function sendEmail(
  db: any,
  options: EmailDispatchOptions
): Promise<{ success: boolean; error?: string; deduplicated?: boolean }> {
  const { to, name, subject, templateType, textBody } = options;

  // 1. Deduplication check: prevent multiple identical registration acknowledgements
  try {
    const existing = await db
      .prepare('SELECT id FROM email_logs WHERE LOWER(recipient_email) = LOWER(?) AND template_type = ?')
      .bind(to.trim(), templateType)
      .first();

    if (existing && templateType === 'REGISTRATION_RECEIVED') {
      console.log(`[Email] Deduplication: Acknowledgement email already sent to ${to}`);
      return { success: true, deduplicated: true };
    }
  } catch (err) {
    // If table check fails, log and continue
    console.warn('[Email] Warning: could not check email_logs deduplication', err);
  }

  // 2. Format / Log the outbound message
  const logId = crypto.randomUUID();
  console.log(`[Email Dispatch] [${templateType}] To: ${to} | Subject: "${subject}"`);

  // 3. Persist audit log
  try {
    await db
      .prepare(`
        INSERT INTO email_logs (id, recipient_email, recipient_name, subject, template_type, status, details)
        VALUES (?, ?, ?, ?, ?, 'SENT', ?)
      `)
      .bind(logId, to.trim(), name, subject, templateType, textBody)
      .run();
  } catch (err: any) {
    console.error('[Email] Failed to persist email_log record:', err?.message || err);
  }

  return { success: true };
}

export async function sendRegistrationAcknowledgementEmail(
  db: any,
  user: { name: string; email: string }
): Promise<{ success: boolean }> {
  const exactBody = `Dear ${user.name},

Thank you for registering with Archi Draft.

We have successfully received your registration and the supporting document you submitted.

**Your registration status: Pending Review**

Our Admin team will review your submitted information and proof document. Your access to Archi Draft will be enabled once your registration has been approved.

You will receive another email when your registration status is updated.

Thank you for your patience.

Regards,  
**Archi Draft Team**  
Draughtsman Studio`;

  return await sendEmail(db, {
    to: user.email,
    name: user.name,
    subject: 'Archi Draft Registration Received',
    templateType: 'REGISTRATION_RECEIVED',
    textBody: exactBody,
  });
}

export async function sendRegistrationApprovedEmail(
  db: any,
  user: { name: string; email: string; role?: string }
): Promise<{ success: boolean }> {
  const body = `Dear ${user.name},

We are pleased to inform you that your registration with Archi Draft has been APPROVED.

Your account is now fully active. You may log in to the application and access all features associated with your role.

Welcome aboard!

Regards,  
**Archi Draft Team**  
Draughtsman Studio`;

  return await sendEmail(db, {
    to: user.email,
    name: user.name,
    subject: 'Archi Draft Registration Approved',
    templateType: 'REGISTRATION_APPROVED',
    textBody: body,
  });
}

export async function sendRegistrationRejectedEmail(
  db: any,
  user: { name: string; email: string; role?: string },
  reason?: string
): Promise<{ success: boolean }> {
  const reasonText = reason && reason.trim() ? `\n\nReason for rejection:\n${reason.trim()}` : '';

  const body = `Dear ${user.name},

Thank you for your interest in Archi Draft.

Following manual review of your submitted registration and qualification proof, we regret to inform you that your registration was not approved.${reasonText}

If you believe this is an error or would like to submit updated documentation, please contact the studio administration team.

Regards,  
**Archi Draft Team**  
Draughtsman Studio`;

  return await sendEmail(db, {
    to: user.email,
    name: user.name,
    subject: 'Archi Draft Registration Update',
    templateType: 'REGISTRATION_REJECTED',
    textBody: body,
  });
}

