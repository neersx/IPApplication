using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Attachments
{
    public class CaseViewAttachmentsFacts : FactBase
    {
        public class AttachmentsProviderFixture : IFixture<ICaseViewAttachmentsProvider>
        {
            public AttachmentsProviderFixture(InMemoryDbContext db)
            {
                SecurityContext = Substitute.For<ISecurityContext>();
                SubjectSecurityProvider = Substitute.For<ISubjectSecurityProvider>();
                cultureResolver = Substitute.For<IPreferredCultureResolver>();
                cultureResolver.Resolve().ReturnsForAnyArgs("enu");

                Subject = new CaseViewAttachmentsProvider(db, SecurityContext, SubjectSecurityProvider, cultureResolver);
            }

            public ISecurityContext SecurityContext { get; set; }

            public ISubjectSecurityProvider SubjectSecurityProvider { get; set; }

            public IPreferredCultureResolver cultureResolver { get; set; }

            public ICaseViewAttachmentsProvider Subject { get; }
        }

        [Fact]
        public async Task ReturnsValidAttachmentsForExternalUser()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SecurityContext.User.Returns(new User("external", true, new Profile(3, "user")));
            var @case = new CaseBuilder().Build().In(Db);
            var criteria = new Criteria().In(Db);
            var action = new Action("oAction") { Code = "A" }.In(Db);
            var oa = new OpenAction(action, @case, 1, "started", criteria).In(Db);
            var ev = new Event { Id = Fixture.Integer(), ControllingAction = oa.Action.Code }.In(Db);
            var cev = new CaseEvent(@case.Id, ev.Id, 1)
            {
                CreatedByCriteriaKey = criteria.Id,
                CreatedByActionKey = action.Code
            }.In(Db);

            new ValidEvent(criteria, ev).In(Db);
            new CaseSearchResult(@case.Id, 0, true).In(Db);
            var act = new Activity
            {
                CaseId = @case.Id,
                ActivityTypeId = 2,
                ActivityCategoryId = 1,
                ActivityCategory = new TableCode(1, 1, "tb1Category").In(Db),
                ActivityType = new TableCode(2, 2, "tb2Type").In(Db),
                Cycle = 1,
                EventId = cev.EventNo,
                ActivityDate = Fixture.Date()
            }.In(Db);
            var tc3 = new TableCode(3, 3, "Attachment Type").In(Db);
            var tc4 = new TableCode(4, 4, "language").In(Db);
            var attachment = new ActivityAttachment(act.Id, 1) { AttachmentName = Fixture.String(), Language = tc4, LanguageId = tc4.Id, AttachmentType = tc3, AttachmentTypeId = tc3.Id, PublicFlag = 1m, Activity = act, ActivityId = act.Id }.In(Db);

            var result = f.Subject.GetAttachments(@case.Id).ToArray();
            Assert.Single(result);
            Assert.Equal(attachment.AttachmentName, result[0].AttachmentName);
            Assert.Equal(act.ActivityCategory.Name, result[0].ActivityCategory);
            Assert.Equal(tc4.Name, result[0].Language);
            Assert.Equal(tc3.Name, result[0].AttachmentType);
            Assert.Equal(act.ActivityType.Name, result[0].ActivityType);
            Assert.Equal(true, result[0].IsPublic);
            Assert.Equal(string.Empty, result[0].EventDescription);
            Assert.Equal((short)1, result[0].EventCycle);
        }

        [Fact]
        public async Task ReturnsValidAttachmentsForInternalUser()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SecurityContext.User.Returns(new User("internal", false, new Profile(3, "user")));
            var @case = new CaseBuilder().Build().In(Db);
            var criteria = new Criteria().In(Db);
            var action = new Action("oAction") { Code = "A" }.In(Db);
            var oa = new OpenAction(action, @case, 1, "started", criteria) { ActionId = action.Code }.In(Db);
            var ev = new Event { Id = Fixture.Integer(), ControllingAction = oa.Action.Code, Description = "descriptions" }.In(Db);
            var cev = new CaseEvent(@case.Id, ev.Id, 1)
            {
                CreatedByCriteriaKey = criteria.Id,
                CreatedByActionKey = action.Code
            }.In(Db);

            new ValidEvent(cev.CreatedByCriteriaKey ?? 0, cev.EventNo).In(Db);
            new CaseSearchResult(@case.Id, 0, true).In(Db);
            var act = new Activity
            {
                CaseId = @case.Id,
                ActivityCategory = new TableCode(1, 1, "tb1Category").In(Db),
                ActivityCategoryId = 1,
                ActivityType = new TableCode(2, 2, "tb2Type").In(Db),
                ActivityTypeId = 2,
                Cycle = 1,
                EventId = ev.Id,
                ActivityDate = Fixture.Date()
            }.In(Db);
            var tc3 = new TableCode(3, 3, "Attachment Type").In(Db);
            var tc4 = new TableCode(4, 4, "language").In(Db);
            var tc32 = new TableCode(5, 5, "Attachment Type2").In(Db);

            var attachment = new ActivityAttachment(act.Id, 1) { AttachmentName = "abc", Language = tc4, LanguageId = tc4.Id, AttachmentType = tc3, AttachmentTypeId = tc3.Id, PublicFlag = 0m }.In(Db);
            act.Attachments.Add(attachment);

            new ActivityAttachment(act.Id, 1) { AttachmentName = null, Language = tc4, LanguageId = tc4.Id, AttachmentType = tc32, AttachmentTypeId = tc32.Id, PublicFlag = 0m, FileName = @"C:\abc.de" }.In(Db);

            var result = f.Subject.GetAttachments(@case.Id).ToArray();
            Assert.Equal(2, result.Length);
            Assert.Equal(act.ActivityCategory.Name, result[0].ActivityCategory);
            Assert.Equal(ev.Description, result[0].EventDescription);
            Assert.Equal(tc4.Name, result[0].Language);
            Assert.Equal(tc32.Name, result[0].AttachmentType);
            Assert.Equal(act.ActivityType.Name, result[0].ActivityType);
            Assert.Equal(false, result[0].IsPublic);
            Assert.Equal("abc.de", result[0].AttachmentName);
            Assert.Equal(attachment.AttachmentName, result[1].AttachmentName);
            Assert.Equal(tc3.Name, result[1].AttachmentType);
        }

        [Fact]
        public async Task ReturnsValidAttachmentsForInternalUserFromPriorArt()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SecurityContext.User.Returns(new User("internal", false, new Profile(3, "user")));
            var @case = new CaseBuilder().Build().In(Db);
            var case2 = new CaseBuilder().Build().In(Db);
            var criteria = new Criteria().In(Db);
            var action = new Action("oAction") { Code = "A" }.In(Db);
            var oa = new OpenAction(action, case2, 1, "started", criteria) { ActionId = action.Code }.In(Db);
            var ev = new Event { Id = Fixture.Integer(), ControllingAction = oa.Action.Code, Description = "descriptions" }.In(Db);
            var cev = new CaseEvent(case2.Id, ev.Id, 1)
            {
                CreatedByCriteriaKey = criteria.Id,
                CreatedByActionKey = action.Code
            }.In(Db);

            new ValidEvent(cev.CreatedByCriteriaKey ?? 0, cev.EventNo).In(Db);

            new CaseSearchResult(@case.Id, 9, false).In(Db);
            var act = new Activity
            {
                CaseId = case2.Id,
                ActivityCategory = new TableCode(1, 1, "tb1Category").In(Db),
                ActivityCategoryId = 1,
                ActivityType = new TableCode(2, 2, "tb2Type").In(Db),
                ActivityTypeId = 2,
                Cycle = 1,
                EventId = ev.Id,
                ActivityDate = Fixture.Date(),
                PriorartId = 9
            }.In(Db);
            var tc3 = new TableCode(3, 3, "Attachment Type").In(Db);
            var tc4 = new TableCode(4, 4, "language").In(Db);

            var attachment = new ActivityAttachment(act.Id, 1) { AttachmentName = "abc", Language = tc4, LanguageId = tc4.Id, AttachmentType = tc3, AttachmentTypeId = tc3.Id, PublicFlag = 0m }.In(Db);

            var result = f.Subject.GetAttachments(@case.Id).ToArray();
            Assert.Equal(1, result.Length);
            Assert.Equal(attachment.AttachmentName, result[0].AttachmentName);
            Assert.Equal(act.ActivityCategory.Name, result[0].ActivityCategory);
            Assert.Null(result[0].EventDescription);
            Assert.Equal(tc4.Name, result[0].Language);
            Assert.Equal(tc3.Name, result[0].AttachmentType);
            Assert.Equal(act.ActivityType.Name, result[0].ActivityType);
            Assert.Equal(false, result[0].IsPublic);
            Assert.Equal(true, result[0].IsPriorArt);
        }

        [Fact]
        public void ReturnsNoAttachmentsIfNoSubjectSecurity()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(false);
            f.SecurityContext.User.Returns(new User("internal", false, new Profile(3, "user")));

            var data = f.Subject.GetActivityWithAttachments(10).ToArray();
            Assert.Empty(data);
        }

        [Fact]
        public void ReturnsAttachmentsQuerable()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
            f.SecurityContext.User.Returns(new User("internal", false, new Profile(3, "user")));

            var activity1 = new Activity { CaseId = 10, Id = 1, Summary = "A1" }.In(Db);
            activity1.Attachments.Add(new ActivityAttachment().In(Db));

            var activity2 = new Activity { CaseId = 10, Id = 2, Summary = "A2" }.In(Db);
            activity2.Attachments.Add(new ActivityAttachment().In(Db));

            new Activity { CaseId = 10 }.In(Db);

            var activityOtherCase = new Activity { CaseId = 11, Id = 5, Summary = "Z" }.In(Db);
            activityOtherCase.Attachments.Add(new ActivityAttachment().In(Db));

            var data = f.Subject.GetActivityWithAttachments(10).ToArray();
            Assert.Equal(2, data.Length);
        }

        [Fact]
        public void ReturnsAttachmentQueryableForExternalUser()
        {
            var f = new AttachmentsProviderFixture(Db);
            f.SubjectSecurityProvider.HasAccessToSubject(ApplicationSubject.Attachments).Returns(true);
            f.SecurityContext.User.Returns(new User("external", true, new Profile(3, "user")));

            var activity1 = new Activity { CaseId = 10, Id = 1, Summary = "A" }.In(Db);
            activity1.Attachments.Add(new ActivityAttachment { PublicFlag = 1 }.In(Db));

            var activity2 = new Activity { CaseId = 10, Id = 2, Summary = "A2" }.In(Db);
            activity2.Attachments.Add(new ActivityAttachment { PublicFlag = 0 }.In(Db));

            new Activity { CaseId = 10 }.In(Db);

            var activityOtherCase = new Activity { CaseId = 11, Id = 3, Summary = "Z1" }.In(Db);
            activityOtherCase.Attachments.Add(new ActivityAttachment().In(Db));

            var data = f.Subject.GetActivityWithAttachments(10).ToArray();
            Assert.Equal(1, data.Length);
        }
    }
}