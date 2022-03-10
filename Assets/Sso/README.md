# Installation instructions for SSO

## Setup

Install `jwt-token.crt` certificate as follows:

1. Click **Start**, click **Start Search**, type **mmc**, and then press ENTER.
2. On the **File** menu, click **Add/Remove Snap-in**.
3. Under **Available snap-ins**, click **Certificates**,and then click **Add**.
4. Under **This snap-in will always manage certificates for**, click **Computer account**, and then click **Next**.
5. Click **Local computer**, and click **Finish**.
6. If you have no more snap-ins to add to the console, click **OK**.
7. In the console tree, double-click **Certificates**.
8. Right-click the **Trusted Root Certification Authorities** store.
9. Click **Import** to import the certificates and follow the steps in the Certificate Import Wizard.


## GUK and your @cpaglobal.com 

You could choose to associate a USERIDENTITY row with your @cpaglobal.com account for dev/testing.  

```sql
UPDATE USERIDENTITY 
 	SET GUK = '<guk>'
 	WHERE LOGINID = '<login id you want to associate with your @cpaglobal.com account>'
```