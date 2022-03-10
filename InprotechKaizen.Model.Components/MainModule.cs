using System;
using System.Configuration;
using System.Diagnostics.CodeAnalysis;
using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Components.Accounting.Wip;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks;
using InprotechKaizen.Model.Components.Cases.PostModificationTasks;
using InprotechKaizen.Model.Components.Cases.Restrictions;
using InprotechKaizen.Model.Components.Cases.Rules;
using InprotechKaizen.Model.Components.Cases.Validation;
using InprotechKaizen.Model.Components.ChargeGeneration;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Components.ContactActivities;
using InprotechKaizen.Model.Components.DataValidation;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Names.TrustAccounting;
using InprotechKaizen.Model.Components.Names.Validation;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Components.Queries;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.Security.Cryptography;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components
{
    public class MainModule : Module
    {
        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SqlDbContext>().AsImplementedInterfaces().InstancePerLifetimeScope();
            builder.RegisterType<SqlDbArtifacts>().As<IDbArtifacts>();
            
            builder.RegisterType<SqlHelper>().As<ISqlHelper>();

            var appSettings = ConfigurationManager.AppSettings["LegacySqlVersion"];
            builder.Register<ISqlStatementColumnReader>((c, p) =>
                   {
                       if (Convert.ToBoolean(appSettings)) return new SqlStatementColumnReaderLegacy(new SqlDbContext());
                       return new SqlStatementColumnReader(new SqlDbContext());
                   })
                   .As<ISqlStatementColumnReader>();
            
            builder.RegisterType<ExternalApplicationContext>()
                .As<IExternalApplicationContext>()
                .InstancePerRequest();

            builder.RegisterType<PolicingEngine>().As<IPolicingEngine>();
            builder.RegisterType<CriteriaReader>().As<ICriteriaReader>();
            
            builder.RegisterType<ExternalOfficialNumberValidator>().As<IExternalOfficialNumberValidator>();
            builder.RegisterType<AliasTypeValidator>().As<IAliasTypeValidator>();
            builder.RegisterType<DataEntryTaskDispatcher>().As<IDataEntryTaskDispatcher>();
            builder.RegisterType<DataEntryTaskHandlerInputFormatter>().As<IDataEntryTaskHandlerInputFormatter>();
            builder.RegisterType<UpdateRelatedEventsTask>().As<IPostCaseDetailModificationTask>();
            builder.RegisterType<OfficialNumberDateInForceUpdateTask>().As<IPostCaseDetailModificationTask>();
            builder.RegisterType<ExternalDateRuleValidator>().As<IDateRuleValidator>();
            builder.Register(c => DateTime.Now);
            builder.RegisterType<EthicalWall>().As<IEthicalWall>();
            builder.RegisterType<IdentityBoundCryptoService>().As<IIdentityBoundCryptoService>();
            builder.RegisterType<CaseCreditLimitChecker>().As<ICaseCreditLimitChecker>();
            builder.RegisterType<ExternalDataValidator>().As<IExternalDataValidator>();
            builder.RegisterType<CurrentOfficialNumberUpdater>().As<ICurrentOfficialNumberUpdater>();
            builder.RegisterType<RestrictableCaseNames>().As<IRestrictableCaseNames>();
            builder.RegisterType<CreateActivityAttachment>().As<ICreateActivityAttachment>();
            builder.RegisterType<NameAccessSecurity>().As<INameAccessSecurity>();
            builder.RegisterType<NewNameProcessor>().As<INewNameProcessor>();
            builder.RegisterType<NameValidator>().As<INameValidator>();
            builder.RegisterType<DefaultNameTypeClassification>().As<IDefaultNameTypeClassification>();
            builder.RegisterType<LastInternalCodeGenerator>().As<ILastInternalCodeGenerator>();
            builder.RegisterType<NameRelationValidator>().As<INameRelationValidator>();
            
            builder.RegisterType<Classes>().As<IClasses>();
            builder.RegisterType<GoodsServices>().As<IGoodsServices>();
            builder.RegisterType<ComponentResolver>().As<IComponentResolver>();
            builder.RegisterType<MultipleClassApplicationCountries>().As<IMultipleClassApplicationCountries>();
            builder.RegisterType<PresentationColumnsResolver>().As<IPresentationColumnsResolver>();
            builder.RegisterType<TrustAccounting>().As<ITrustAccounting>();

            builder.RegisterType<SiteControlReader>().As<ISiteControlReader>();
            builder.RegisterType<SiteControlCache>()
                   .As<ISiteControlCache>()
                   .As<IDisableApplicationCache>()
                   .SingleInstance();

            builder.RegisterType<SiteControlCacheManager>().As<ISiteControlCacheManager>();
            builder.RegisterType<ChargeGenerator>().As<IChargeGenerator>();
            builder.RegisterType<GetWipCostCommand>().As<IGetWipCostCommand>();

            builder.RegisterType<LegacyFormattingDataProvider>().As<ILegacyFormattingDataProvider>();
            builder.RegisterType<StandardReportFormattingDataResolver>().As<IStandardReportFormattingDataResolver>();
        }
    }
}