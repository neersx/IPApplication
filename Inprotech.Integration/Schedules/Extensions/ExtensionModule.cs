using Autofac;
using Autofac.Features.AttributeFilters;
using Inprotech.Integration.Schedules.Extensions.Epo;
using Inprotech.Integration.Schedules.Extensions.FileApp;
using Inprotech.Integration.Schedules.Extensions.Innography;
using Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair;
using Inprotech.Integration.Schedules.Extensions.Uspto.Tsdr;
using CreateSchedule = Inprotech.Integration.Schedules.Extensions.Uspto.PrivatePair.CreateSchedule;

namespace Inprotech.Integration.Schedules.Extensions
{
    public class ExtensionsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DataSourceSchedule>().As<IDataSourceSchedule>();

            builder.RegisterType<CreateSchedule>()
                   .Keyed<ICreateSchedule>(DataSourceType.UsptoPrivatePair);

            builder.RegisterType<Uspto.Tsdr.CreateSchedule>()
                   .Keyed<ICreateSchedule>(DataSourceType.UsptoTsdr);

            builder.RegisterType<Epo.CreateSchedule>()
                   .Keyed<ICreateSchedule>(DataSourceType.Epo)
                   .WithAttributeFiltering();

            builder.RegisterType<Innography.CreateSchedule>()
                   .Keyed<ICreateSchedule>(DataSourceType.IpOneData)
                   .WithAttributeFiltering();

            builder.RegisterType<FileApp.CreateSchedule>()
                   .Keyed<ICreateSchedule>(DataSourceType.File)
                   .WithAttributeFiltering();

            builder.RegisterType<InnographySchedulePrerequisite>()
                   .Keyed<IDataSourceSchedulePrerequisites>(DataSourceType.IpOneData);

            builder.RegisterType<EpoSchedulePrerequisite>()
                   .Keyed<IDataSourceSchedulePrerequisites>(DataSourceType.Epo);

            builder.RegisterType<PrivatePairSchedulePrerequisite>()
                   .Keyed<IDataSourceSchedulePrerequisites>(DataSourceType.UsptoPrivatePair);
            
            builder.RegisterType<TsdrSchedulePrerequisite>()
                   .Keyed<IDataSourceSchedulePrerequisites>(DataSourceType.UsptoTsdr);

            builder.RegisterType<FileAppSchedulePrerequisite>()
                   .Keyed<IDataSourceSchedulePrerequisites>(DataSourceType.File);

            builder.RegisterType<ValidateUsptoRecoveryScheduleStatus>()
                   .Keyed<IValidateRecoveryScheduleStatus>(DataSourceType.UsptoPrivatePair);
        }
    }
}