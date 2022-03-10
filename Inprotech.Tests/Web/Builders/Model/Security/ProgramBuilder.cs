using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ProgramBuilder : IBuilder<Program>
    {
        public string Id { get; set; }

        public string Name { get; set; }

        public string ProgramGroup { get; set; }

        public Program ParentProgram { get; set; }

        public Program Build()
        {
            return new Program(Id ?? Fixture.String(), 
                               Name ?? Fixture.String(), 
                               ProgramGroup?? "C", 
                               ParentProgram);
        }
    }
}