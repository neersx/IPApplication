using Autofac;
using InprotechKaizen.Model;

namespace Inprotech.Web.Configuration.ValidCombinations
{
    public class ValidCombinationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ValidCombinationValidator>().As<IValidCombinationValidator>();
            builder.RegisterType<ValidActionsController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Action);
            builder.RegisterType<ValidBasisController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Basis);
            builder.RegisterType<ValidCategoryController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Category);
            builder.RegisterType<ValidChecklistController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Checklist);
            builder.RegisterType<ValidPropertyTypesController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.PropertyType);
            builder.RegisterType<ValidRelationshipController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Relationship);
            builder.RegisterType<ValidStatusController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.Status);
            builder.RegisterType<ValidSubTypeController>()
                .As<IValidCombinationBulkController>()
                .WithMetadata("Name", KnownValidCombinationSearchTypes.SubType);
            builder.RegisterType<ValidJurisdictionDetails>().As<IValidJurisdictionsDetails>();
            builder.RegisterType<ValidPropertyTypes>().As<IValidPropertyTypes>();
            builder.RegisterType<ValidActions>().As<IValidActions>();
            builder.RegisterType<ValidCategories>().As<IValidCategories>();
            builder.RegisterType<ValidBasisImp>().As<IValidBasisImp>();
            builder.RegisterType<ValidSubTypes>().As<IValidSubTypes>();
        }
    }
}
