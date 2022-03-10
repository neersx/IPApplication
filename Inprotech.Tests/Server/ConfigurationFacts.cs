using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Web.Http;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.ExternalApplications.Crm;
using Inprotech.Integration.Qos;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Diagnostics;
using Inprotech.Web.DocumentManagement;
using Inprotech.Web.ExchangeIntegration;
using Inprotech.Web.Security;
using Inprotech.Web.Security.ResetPassword;
using Xunit;

namespace Inprotech.Tests.Server
{
    public class ConfigurationFacts
    {
        [Fact]
        public void AllControllersRequireAuthorization()
        {
            var exclusions = new HashSet<Type>(new[]
            {
                typeof(SignInController),
                typeof(SignInViewController),
                typeof(SignOutController),
                typeof(CrmController),
                typeof(ExternalApplicationController),
                typeof(ExternalApplicationWithUserController),
                typeof(StatusController),
                typeof(ResetPasswordController),
                typeof(DmsAuthRedirectController),
                typeof(GraphAuthRedirectController)
            });

            foreach (var c in AllRegisteredControllers.Get().Except(exclusions))
            {
              Assert.True(
                            c.GetCustomAttribute<AuthorizeAttribute>() != null || c.GetCustomAttribute<RequiresApiKeyAttribute>() != null,
                            $"Controller {c} is not secure.");
            }
        }
    }
}