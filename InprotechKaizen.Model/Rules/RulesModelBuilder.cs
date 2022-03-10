using System.Data.Entity;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Rules
{
    public class RulesModelBuilder : IModelBuilder
    {
        public void Build(DbModelBuilder modelBuilder)
        {
            ConfigureCriteria(modelBuilder);

            ConfigureDataEntryTask(modelBuilder);

            ConfigureUserControl(modelBuilder);

            ConfigureRolesControl(modelBuilder);

            ConfigureGroupControl(modelBuilder);

            ConfigureValidEvent(modelBuilder);

            ConfigureDueDateCalc(modelBuilder);

            ConfigureRelatedEvent(modelBuilder);

            ConfigureDatesLogic(modelBuilder);

            ConfigureReminderRule(modelBuilder);

            modelBuilder.Entity<DocumentRequirement>()
                        .HasRequired(dr => dr.Document)
                        .WithMany()
                        .HasForeignKey(dr => dr.DocumentId);

            modelBuilder.Entity<Inherits>();
            modelBuilder.Entity<NameTypeMap>();
            modelBuilder.Entity<RequiredEventRule>();
            modelBuilder.Entity<DateAdjustment>();
            modelBuilder.Entity<TextType>();
            modelBuilder.Entity<ChecklistItem>();
            modelBuilder.Entity<EdeCaseEventRule>();
            modelBuilder.Entity<FeesCalculation>();
            modelBuilder.Entity<NameCriteria>();
            modelBuilder.Entity<Question>();
            modelBuilder.Entity<ChecklistLetter>();
        }

        static void ConfigureDueDateCalc(DbModelBuilder modelBuilder)
        {
            var dueDateCalc = modelBuilder.Entity<DueDateCalc>();
            dueDateCalc.HasRequired(_ => _.Criteria)
                       .WithMany()
                       .HasForeignKey(_ => _.CriteriaId);

            dueDateCalc.HasOptional(_ => _.FromEvent)
                       .WithMany()
                       .HasForeignKey(_ => _.FromEventId);

            dueDateCalc.HasOptional(_ => _.CompareEvent)
                       .WithMany()
                       .HasForeignKey(_ => _.CompareEventId);

            dueDateCalc.HasOptional(_ => _.Jurisdiction)
                       .WithMany()
                       .HasForeignKey(_ => _.JurisdictionId);

            dueDateCalc.HasOptional(_ => _.OverrideLetter)
                       .WithMany()
                       .HasForeignKey(_ => _.OverrideLetterId);

            dueDateCalc.HasOptional(_ => _.CompareRelationship)
                       .WithMany()
                       .HasForeignKey(_ => _.CompareRelationshipId);
        }

        static void ConfigureDatesLogic(DbModelBuilder modelBuilder)
        {
            var datesLogic = modelBuilder.Entity<DatesLogic>();
            datesLogic.HasOptional(_ => _.CompareEvent)
                      .WithMany()
                      .HasForeignKey(_ => _.CompareEventId);

            datesLogic.HasOptional(_ => _.CaseRelationship)
                      .WithMany()
                      .HasForeignKey(_ => _.CaseRelationshipId);
        }

        static void ConfigureRelatedEvent(DbModelBuilder modelBuilder)
        {
            var relatedEventRule = modelBuilder.Entity<RelatedEventRule>();

            relatedEventRule.HasOptional(_ => _.RelatedEvent)
                            .WithMany()
                            .HasForeignKey(_ => _.RelatedEventId);
        }

        static void ConfigureReminderRule(DbModelBuilder modelBuilder)
        {
            var relatedEventRule = modelBuilder.Entity<ReminderRule>();

            relatedEventRule.HasOptional(_ => _.Letter)
                            .WithMany()
                            .HasForeignKey(_ => _.LetterNo);

            relatedEventRule.HasOptional(_ => _.RemindEmployee)
                            .WithMany()
                            .HasForeignKey(_ => _.RemindEmployeeId);

            relatedEventRule.HasOptional(_ => _.NameType)
                            .WithMany()
                            .HasForeignKey(_ => _.NameTypeId);

            relatedEventRule.HasOptional(_ => _.NameRelation)
                            .WithMany()
                            .HasForeignKey(_ => _.RelationshipId);

            relatedEventRule.HasOptional(_ => _.LetterFee)
                            .WithMany()
                            .HasForeignKey(_ => _.LetterFeeId);
        }

        static void ConfigureValidEvent(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<ValidEvent>().HasKey(ec => new {ec.CriteriaId, ec.EventId});

            modelBuilder.Entity<ValidEvent>().HasRequired(ve => ve.Event)
                        .WithMany(e => e.ValidEvents)
                        .HasForeignKey(ve => ve.EventId);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(ve => ve.DueDateCalcs)
                        .WithRequired(ddc => ddc.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(_ => _.DatesLogic)
                        .WithRequired(_ => _.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(_ => _.RelatedEvents)
                        .WithRequired(_ => _.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(_ => _.Reminders)
                        .WithRequired(_ => _.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(_ => _.NameTypeMaps)
                        .WithRequired(_ => _.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasMany(_ => _.RequiredEvents)
                        .WithRequired(_ => _.ValidEvent);

            modelBuilder.Entity<ValidEvent>()
                        .HasOptional(_ => _.Name)
                        .WithMany()
                        .HasForeignKey(_ => _.DueDateRespNameId);

            modelBuilder.Entity<ValidEvent>()
                        .HasOptional(_ => _.DueDateRespNameType)
                        .WithMany()
                        .HasForeignKey(_ => _.DueDateRespNameTypeCode);

            modelBuilder.Entity<ValidEvent>()
                        .HasOptional(_ => _.ChangeStatus)
                        .WithMany()
                        .HasForeignKey(_ => _.ChangeStatusId);

            modelBuilder.Entity<ValidEvent>()
                        .HasOptional(_ => _.ChangeRenewalStatus)
                        .WithMany()
                        .HasForeignKey(_ => _.ChangeRenewalStatusId);
        }

        [SuppressMessage("Microsoft.Maintainability", "CA1506:AvoidExcessiveClassCoupling")]
        static void ConfigureCriteria(DbModelBuilder modelBuilder)
        {
            var criteria = modelBuilder.Entity<Criteria>();
            criteria.HasMany(c => c.DataEntryTasks)
                    .WithRequired()
                    .HasForeignKey(c => c.CriteriaId);

            criteria.HasMany(c => c.ValidEvents)
                    .WithOptional()
                    .HasForeignKey(ec => ec.CriteriaId);

            criteria.HasOptional(u => u.Action)
                    .WithMany()
                    .HasForeignKey(m => m.ActionId);

            criteria.HasOptional(u => u.Country)
                    .WithMany()
                    .HasForeignKey(m => m.CountryId);

            criteria.HasOptional(u => u.PropertyType)
                    .WithMany()
                    .HasForeignKey(m => m.PropertyTypeId);

            criteria.HasOptional(u => u.SubType)
                    .WithMany()
                    .HasForeignKey(m => m.SubTypeId);

            criteria.HasOptional(u => u.Basis)
                    .WithMany()
                    .HasForeignKey(m => m.BasisId);

            criteria.HasOptional(u => u.Office)
                    .WithMany()
                    .HasForeignKey(m => m.OfficeId);

            criteria.HasOptional(u => u.DataExtractModule)
                    .WithMany()
                    .Map(m => m.MapKey("DATAEXTRACTID"));

            criteria.HasOptional(u => u.CaseType)
                    .WithMany()
                    .HasForeignKey(x => x.CaseTypeId);

            criteria.HasOptional(u => u.CaseCategory)
                    .WithMany()
                    .HasForeignKey(x => new {x.CaseTypeId, x.CaseCategoryId});

            criteria.HasOptional(c => c.TableCode)
                    .WithMany()
                    .HasForeignKey(c => c.TableCodeId);
        }

        static void ConfigureUserControl(DbModelBuilder modelBuilder)
        {
            var userControl = modelBuilder.Entity<UserControl>();
            userControl.HasKey(uc => new {uc.UserId, uc.CriteriaNo, uc.DataEntryTaskId});
            userControl.HasRequired(uc => uc.DataEntryTask).WithMany(
                                                                     dc => dc.UsersAllowed
                                                                    ).HasForeignKey(uc => new {uc.CriteriaNo, uc.DataEntryTaskId});
        }

        static void ConfigureRolesControl(DbModelBuilder modelBuilder)
        {
            var roleControl = modelBuilder.Entity<RolesControl>();
            roleControl.HasKey(rc => new {rc.RoleId, rc.CriteriaId, rc.DataEntryTaskId});
            roleControl.HasRequired(rc => rc.DataEntryTask).WithMany(
                                                                     dc => dc.RolesAllowed
                                                                    ).HasForeignKey(rc => new {rc.CriteriaId, rc.DataEntryTaskId});
        }

        static void ConfigureGroupControl(DbModelBuilder modelBuilder)
        {
            var groupControl = modelBuilder.Entity<GroupControl>();
            groupControl.HasKey(gc => new {gc.SecurityGroup, gc.CriteriaId, gc.EntryId});
            groupControl.HasRequired(gc => gc.Entry)
                        .WithMany(dc => dc.GroupsAllowed)
                        .HasForeignKey(gc => new {gc.CriteriaId, gc.EntryId});
        }

        static void ConfigureDataEntryTask(DbModelBuilder modelBuilder)
        {
            var dataEntryTask = modelBuilder.Entity<DataEntryTask>();
            dataEntryTask.HasKey(dc => new {dc.CriteriaId, dc.Id});
            dataEntryTask.HasMany(dc => dc.AvailableEvents)
                         .WithOptional()
                         .HasForeignKey(dc => new {dc.CriteriaId, dc.DataEntryTaskId});

            dataEntryTask.HasRequired(dc => dc.Criteria)
                         .WithMany()
                         .HasForeignKey(dc => dc.CriteriaId);

            dataEntryTask.HasOptional(dc => dc.CaseStatus)
                         .WithMany()
                         .HasForeignKey(dc => dc.CaseStatusCodeId);

            dataEntryTask.HasOptional(dc => dc.RenewalStatus)
                         .WithMany()
                         .HasForeignKey(dc => dc.RenewalStatusId);

            dataEntryTask.HasOptional(dc => dc.OfficialNumberType)
                         .WithMany()
                         .HasForeignKey(dc => dc.OfficialNumberTypeId);

            dataEntryTask.HasOptional(dc => dc.FileLocation)
                         .WithMany()
                         .HasForeignKey(dc => dc.FileLocationId);

            dataEntryTask.HasMany(det => det.DocumentRequirements)
                         .WithRequired()
                         .HasForeignKey(dr => new {dr.CriteriaId, dr.DataEntryTaskId});

            dataEntryTask.HasMany(det => det.TaskSteps)
                         .WithOptional()
                         .HasForeignKey(dr => new {dr.CriteriaId, dr.EntryNumber});

            dataEntryTask.HasOptional(de => de.DisplayEvent)
                         .WithMany()
                         .HasForeignKey(de => de.DisplayEventNo);

            dataEntryTask.HasOptional(de => de.HideEvent)
                         .WithMany()
                         .HasForeignKey(de => de.HideEventNo);

            dataEntryTask.HasOptional(de => de.DimEvent)
                         .WithMany()
                         .HasForeignKey(de => de.DimEventNo);
        }
    }
}