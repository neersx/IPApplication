using Inprotech.Infrastructure;
using Inprotech.Web.BulkCaseImport;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class SqlXmlConnectionStringBuilderFacts
    {
        
        public class BuildFromMethod
        {
            readonly IGroupedConfig _groupedConfig = Substitute.For<IGroupedConfig>();

            SqlXmlConnectionStringBuilder CreateSubject()
            {
                IGroupedConfig GroupedConfig(string s) => _groupedConfig;
                
                return new SqlXmlConnectionStringBuilder(GroupedConfig);
            }

            [Fact]
            public void ShouldReturnMsSqlOleDbProviderConnectionString()
            {
                var f = CreateSubject();

                const string inputConnectionString = "";
                var outputConnectionString = f.BuildFrom("Data Source=.;Initial Catalog=IPDEV;Integrated Security=false;Application Name=Inprotech;User Id=SYSADM;Password=SYSADM;");

                Assert.NotSame(outputConnectionString, inputConnectionString);
                Assert.Contains("Provider=MSOLEDBSQL", outputConnectionString);
                Assert.Contains("Data Source=.", outputConnectionString);
                Assert.Contains("Database=IPDEV", outputConnectionString);
                Assert.Contains("Application Name=Inprotech", outputConnectionString);
                Assert.Contains("User Id=SYSADM", outputConnectionString);
                Assert.Contains("Password=SYSADM", outputConnectionString);
            }

            [Fact]
            public void ShouldReturnMsSqlOleDbProviderIntegratedSecurityConnectionString()
            {
                var f = CreateSubject();

                const string inputConnectionString = "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech";
                var outputConnectionString = f.BuildFrom(inputConnectionString);

                Assert.NotSame(outputConnectionString, inputConnectionString);
                Assert.Contains("Provider=MSOLEDBSQL", outputConnectionString);
                Assert.Contains("Integrated Security=SSPI", outputConnectionString);
                Assert.Contains("Data Source=.", outputConnectionString);
                Assert.Contains("Database=IPDEV", outputConnectionString);
                Assert.Contains("Application Name=Inprotech", outputConnectionString);
            }

            [Theory]
            [InlineData("MSOLEDBSQL")]
            [InlineData("SQLOLEDB")]
            [InlineData("SQLNCLI11")]
            public void ShouldReturnIndicatedProviderFromConfigSettings(string overridenProviderName)
            {
                var f = CreateSubject();

                _groupedConfig.GetValueOrDefault<string>("SqlBulkLoadProvider")
                              .Returns(overridenProviderName);

                const string inputConnectionString = "";
                var outputConnectionString = f.BuildFrom("Data Source=.;Initial Catalog=IPDEV;Integrated Security=false;Application Name=Inprotech;User Id=SYSADM;Password=SYSADM;");

                Assert.NotSame(outputConnectionString, inputConnectionString);
                Assert.Contains($"Provider={overridenProviderName}", outputConnectionString);
                Assert.Contains("Data Source=.", outputConnectionString);
                Assert.Contains("Database=IPDEV", outputConnectionString);
                Assert.Contains("Application Name=Inprotech", outputConnectionString);
            }
        }
    }
}