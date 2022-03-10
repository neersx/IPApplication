using System;
using System.Security.Principal;
using IManage;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v8
{
    public static class WorkSiteConnector
    {
        public static IManSession Connect(this IManSession manSession, IDmsEventEmitter dmsEventEmitter, IManageSettings.SiteDatabaseSettings settings, string username,
                                          string password)
        {
            if (manSession == null) throw new ArgumentNullException(nameof(manSession));
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            switch (settings.LoginType)
            {
                case IManageSettings.LoginTypes.UsernamePassword:
                    if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
                    {
                        dmsEventEmitter.Emit(new DocumentManagementEvent
                        {
                            Status = Status.Error,
                            Key = KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences
                        });
                        throw new AuthenticationException(
                                                                  "Username and Password are required when Login Type is UsernamePassword",
                                                                  "Ensure 'Login ID' and 'Password' for the Inprotech User is configured accordingly. They can be found in the 'iManage Integration' group of user preferences.");
                    }

                    manSession.Login(username, password);
                    break;
                case IManageSettings.LoginTypes.TrustedLogin:
                    manSession.TrustedLogin();
                    break;
                case IManageSettings.LoginTypes.TrustedLogin2:
                    var intUserToken = WindowsIdentity.GetCurrent().Token.ToInt32();
                    manSession.TrustedLogin2(intUserToken);
                    break;
                case IManageSettings.LoginTypes.UsernameWithImpersonation:
                    if (string.IsNullOrEmpty(username))
                    {
                        dmsEventEmitter.Emit(new DocumentManagementEvent
                        {
                            Status = Status.Error,
                            Key = KnownDocumentManagementEvents.MissingLoginPreference
                        });
                        throw new AuthenticationException(
                                                                  "Username is required when Login Type is UsernameWithImpersonation",
                                                                  "Ensure 'Login ID' for the Inprotech User is configured accordingly. It can be found in the 'iManage Integration' group of user preferences.");
                    }

                    manSession.Login(username, settings.Password);
                    break;
                case IManageSettings.LoginTypes.InprotechUsernameWithImpersonation:
                    manSession.Login(username, settings.Password);
                    break;
            }

            return manSession;
        }
    }
}