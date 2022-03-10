using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Settings;
using Inprotech.Integration.Storage;
using Inprotech.Tests.Integration.DbHelpers;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions
{
    public static class IntegrationCaseExt
    {
        public static Case WithSuccessNotification(this Case @case, string title)
        {
            return IntegrationDbSetup.Do(x =>
                                         {
                                             var @case1 = x.IntegrationDbContext.Set<Case>().Single(_ => _.Id == @case.Id);

                                             x.Insert(new CaseNotification
                                                      {
                                                          Body = title,
                                                          CaseId = @case1.Id,
                                                          CreatedOn = DateTime.Now,
                                                          Case = @case1,
                                                          IsReviewed = false,
                                                          ReviewedBy = null,
                                                          Type = CaseNotificateType.CaseUpdated,
                                                          UpdatedOn = DateTime.Now
                                                      });

                                             return @case;
                                         });
        }

        public static Case WithErrorNotification(this Case @case, string errorMessage = "Unable to locate case in external system. ")
        {
            return IntegrationDbSetup.Do(x =>
            {
                var @case1 = x.IntegrationDbContext.Set<Case>().Single(_ => _.Id == @case.Id);

                x.Insert(new CaseNotification
                {
                    Body = JsonConvert.SerializeObject(new []
                                                       {
                                                           new 
                                                           {
                                                               type = "Error",
                                                               method = "Download",
                                                               message = errorMessage,
                                                               data = new { }
                                                           }
                                                       }),
                    CaseId = @case1.Id,
                    CreatedOn = DateTime.Now,
                    Case = @case1,
                    IsReviewed = false,
                    ReviewedBy = null,
                    Type = CaseNotificateType.Error,
                    UpdatedOn = DateTime.Now
                });

                return @case;
            });
        }

        public static Case InStorage(this Case @case, Guid session, string name, out string fullPath)
        {
            using (var db = new IntegrationDbSetup())
            {
                var ctx = db.IntegrationDbContext;
                var @case1 = ctx.Set<Case>().Single(_ => _.Id == @case.Id);

                var locationResolver = new DataDownloadLocationResolver(
                    new ScheduleExecutionRootResolver(ctx));

                fullPath = locationResolver.Resolve(new DataDownload
                                                    {
                                                        DataSourceType = @case.Source,
                                                        Name = "e2e",
                                                        Id = session
                                                    }, name);

                @case1.FileStore = new FileStore
                                   {
                                       OriginalFileName = name,
                                       Path = fullPath
                                   };
                ctx.SaveChanges();

                return @case;
            }
        }

        public static Case WithDmsEnabled(this Case @case)
        {
            var map = new Dictionary<DataSourceType, string>
                      {
                          {DataSourceType.UsptoPrivatePair, "PrivatePair"},
                          {DataSourceType.UsptoTsdr, "Tsdr"},
                          {DataSourceType.Epo, "Epo"}
                      };

            using (var db = new IntegrationDbSetup())
            {
                db.Insert(new ConfigSetting
                          {
                              Key = $"DmsIntegration.{map[@case.Source]}IntegrationEnabled",
                              Value = "True"
                          });
            }

            return @case;
        }

        public static Case AssociateWith(this Case @case, int? inprotechCaseId)
        {
            using (var db = new IntegrationDbSetup())
            {
                var @case1 = db.IntegrationDbContext.Set<Case>().Single(_ => _.Id == @case.Id);
                @case1.CorrelationId = inprotechCaseId;
                db.IntegrationDbContext.SaveChanges();
            }

            return @case;
        }
    }
}