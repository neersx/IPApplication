using Autofac;

namespace Inprotech.Web.Cases.AssignmentRecordal
{
    public class AssignmentRecordalModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<RecordalSteps>().As<IRecordalSteps>();
            builder.RegisterType<RecordalStepsUpdater>().As<IRecordalStepsUpdater>();
            builder.RegisterType<AffectedCasesSetAgent>().As<IAffectedCasesSetAgent>();
            builder.RegisterType<AssignmentRecordalHelper>().As<IAssignmentRecordalHelper>();
            builder.RegisterType<RecordalMaintenance>().As<IRecordalMaintenance>();
        }
    }
}
