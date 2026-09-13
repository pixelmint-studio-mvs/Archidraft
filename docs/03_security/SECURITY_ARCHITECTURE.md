# SECURITY ARCHITECTURE

## SECURITY PRINCIPLE
**UI ≠ SECURITY.** A hidden button is not security. 

Real security comes from:
Firebase Authentication + Cloudflare Worker Authorization + D1 Logic

## ROLE SECURITY
Users cannot:
- Promote themselves
- Change their own role
- Create an ADMIN account
- Modify another user's role

**Normal registration must never create an ADMIN.**

## ACTIVITY LOG SECURITY
Activity logs are **SERVER GENERATED** and **IMMUTABLE**.

Client applications must not:
- Create activity logs
- Modify activity logs
- Delete activity logs

## IDENTITY SECURITY
**Never trust `userId` sent by the client for critical operations.**
The backend must natively identify the authenticated actor using the verified Firebase token inside Cloudflare Worker endpoints. Do not accept a `userId` parameter in the payload if you are using it to determine who is taking the action.
