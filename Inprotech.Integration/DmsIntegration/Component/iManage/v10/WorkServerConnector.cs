using System;
using System.Configuration;
using System.Threading.Tasks;

namespace Inprotech.Integration.DmsIntegration.Component.iManage.v10
{
    public static class WorkServerConnector
    {
        public static async Task<bool> Connect(this IWorkServerClient workServerClient, IDmsEventEmitter dmsEventEmitter, IManageSettings.SiteDatabaseSettings settings, string username, string password, IAccessTokenManager accessTokenManager, bool force = false)
        {
            if (workServerClient == null) throw new ArgumentNullException(nameof(workServerClient));
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var baseUri = settings.ServerUrl();
            if (baseUri == null)
            {
                throw new ConfigurationErrorsException($"'{settings.Server}' is not recognised as a valid REST API endpoint.");
            }

            var isConnected = false;
            var loginUri = new Uri(baseUri, "api/v1/session/login");
            var networkLoginUri = new Uri(baseUri, "api/v1/session/network-login");

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

                    isConnected = await workServerClient.Login(loginUri, username, password, force);
                    break;
                case IManageSettings.LoginTypes.TrustedLogin:
                    if (string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
                    {
                        dmsEventEmitter.Emit(new DocumentManagementEvent
                        {
                            Status = Status.Error,
                            Key = KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences
                        });
                        throw new AuthenticationException(
                                                                  "Username and Password are required when Login Type is TrustedLogin",
                                                                  "Ensure 'WorkSite Login ID' and 'Password' for the Inprotech User is configured accordingly. They can be found in the 'iManage Integration' group of user preferences.");
                    }

                    isConnected = await workServerClient.Login(networkLoginUri, username, password, force);
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

                    isConnected = await workServerClient.Login(loginUri, username, settings.Password, force);

                    break;
                case IManageSettings.LoginTypes.InprotechUsernameWithImpersonation:
                    isConnected = await workServerClient.Login(loginUri, username, settings.Password, force);
                    break;
                case IManageSettings.LoginTypes.OAuth:
                    isConnected = await accessTokenManager.HasAccessToken(new Uri(settings.AccessTokenUrl), username, string.Empty);
                    if (!isConnected) throw new OAuth2TokenException();
                    break;
                case IManageSettings.LoginTypes.TrustedLogin2:
                    //            {
                    //                loginEndpoint = "network-login";
                    //                context = "Network Login";
                    //            }
                    dmsEventEmitter.Emit(new DocumentManagementEvent
                    {
                        Status = Status.Error,
                        Key = KnownDocumentManagementEvents.NotSupported
                    });
                    throw new NotSupportedException("TrustedLogin2 methods are not supported in Inprotech and iManage Work integration");
            }

            if (!isConnected)
            {
                var key = KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences;
                switch (settings.LoginType)
                {
                    case IManageSettings.LoginTypes.InprotechUsernameWithImpersonation:
                        key = KnownDocumentManagementEvents.FailedConnection;
                        break;

                    case IManageSettings.LoginTypes.UsernamePassword:
                        key = KnownDocumentManagementEvents.FailedLoginOrPasswordPreferences;
                        break;

                    case IManageSettings.LoginTypes.UsernameWithImpersonation:
                        key = KnownDocumentManagementEvents.FailedConnectionIfImpersonationAuthenticationFailure;
                        break;
                }

                dmsEventEmitter.Emit(new DocumentManagementEvent
                {
                    Status = Status.Error,
                    Key = key
                });
            }

            return isConnected;
        }

        public static async Task Disconnect(this IWorkServerClient workServerClient, IManageSettings.SiteDatabaseSettings settings)
        {
            if (settings == null) throw new ArgumentNullException(nameof(settings));

            var baseUri = settings.ServerUrl();
            if (baseUri != null)
            {
                var logoutUri = new Uri(baseUri, "/api/v1/session/logout");
                await workServerClient.Logout(logoutUri);
            }
        }
    }
}