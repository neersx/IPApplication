using Inprotech.Infrastructure.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ValidSecurityTaskBuilder : IBuilder<ValidSecurityTask>
    {
        public short? TaskId { get; set; }
        public bool CanInsert { get; set; }
        public bool CanUpdate { get; set; }
        public bool CanDelete { get; set; }
        public bool CanExecute { get; set; }

        public ValidSecurityTask Build()
        {
            return new ValidSecurityTask
                (
                 TaskId ?? Fixture.Short(),
                 CanInsert,
                 CanUpdate,
                 CanDelete,
                 CanExecute
                );
        }
    }
}