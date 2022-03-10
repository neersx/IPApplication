using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.CaseType
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class CaseTypePicklist : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _caseTypePicklistsDbSetup = new CaseTypePicklistDbSetup();
            _scenario = _caseTypePicklistsDbSetup.Prepare();
        }

        protected CaseTypePicklistDbSetup _caseTypePicklistsDbSetup;
        protected CaseTypePicklistDbSetup.ScenarioData _scenario;
    }
}