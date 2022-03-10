using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class GlobalNameChangeReaderFacts : FactBase
    {
        public GlobalNameChangeReaderFacts()
        {
            _globalNameChangeReader = new GlobalNameChangeReader(Db);
        }

        readonly IGlobalNameChangeReader _globalNameChangeReader;

        public static GlobalNameChangeRequest BuildGlobalNameChange(int caseId)
        {
            return new GlobalNameChangeRequest
            {
                CaseId = caseId
            };
        }

        [Fact]
        public void ShouldReturnRunning()
        {
            BuildGlobalNameChange(1).In(Db);
            Assert.Equal(GlobalNameChangeReader.Running, _globalNameChangeReader.Read(1));
        }
    }
}