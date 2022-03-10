using Autofac;
using Inprotech.Web.Search.Case.CaseSearch.DueDate;

namespace Inprotech.Web.Search.Case.CaseSearch
{
    public class CaseSearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CountryGroup>().As<ICountryGroup>();
            builder.RegisterType<CaseDetailsSelectionVerification>().As<ICaseDetailsSelectionVerification>();
            builder.RegisterType<StatusSelectionVerification>().As<IStatusSelectionVerification>();
             
            builder.RegisterType<DueDateBuilder>().As<IDueDateBuilder>();

            builder.RegisterType<CaseSavedSearch>().As<ICaseSavedSearch>();
            builder.RegisterAssemblyTypes(typeof (AttributesTopicBuilder).Assembly)
                   .Where(x => x.Name.EndsWith("TopicBuilder"))
                   .AsImplementedInterfaces();
        }
    }
}
