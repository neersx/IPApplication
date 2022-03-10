using System.Xml.Linq;
using Inprotech.Setup.Actions;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ImportExistingReportingServicesSettingsFacts
    {
        public class IwsSettingParser
        {
            [Fact]
            public void ShouldReturnValues()
            {
                var xml =@"<reports>
                          <reportingServices rootFolder='Inpro' reportServerBaseUrl='http://localhost/reportserver'
                             parameterLanguage='en-US'>
                             <security username='username' password='password'
                                domain='dev' />
                          </reportingServices>
                       </reports>";
                var xElement = XElement.Parse(xml);
                var result = ImportExistingReportingServicesSettings.IwsSettingParser.ParseReportingServicesSetting(xElement);

                Assert.NotNull(result);
                Assert.Equal(result.RootFolder, "Inpro");
                Assert.Equal(result.MessageSize,105);
                Assert.Equal(result.Timeout, 10);
                Assert.Equal(result.ParameterLanguage, "en-US");
                Assert.Equal(result.ReportServerBaseUrl, "http://localhost/reportserver");
                Assert.NotNull(result.Security);
                Assert.Equal(result.Security.Domain, "dev");
                Assert.Equal(result.Security.Username, "username");
                Assert.Equal(result.Security.Password, "password");
               
            }
        }
    }
}
