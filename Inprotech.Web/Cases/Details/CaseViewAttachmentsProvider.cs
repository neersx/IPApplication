using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using Newtonsoft.Json;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewAttachmentsProvider
    {
        IQueryable<AttachmentItem> GetAttachments(int caseId);

        IQueryable<Activity> GetActivityWithAttachments(int caseId);
    }

    public class CaseViewAttachmentsProvider : ICaseViewAttachmentsProvider
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ISubjectSecurityProvider _subjectSecurity;
        readonly IPreferredCultureResolver _culture;

        public CaseViewAttachmentsProvider(IDbContext dbContext,
                                           ISecurityContext securityContext,
                                           ISubjectSecurityProvider subjectSecurity,
                                           IPreferredCultureResolver culture)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _subjectSecurity = subjectSecurity;
            _culture = culture;
        }

        public IQueryable<Activity> GetActivityWithAttachments(int caseId)
        {
            var isExternal = _securityContext.User.IsExternalUser;

            var activities = new List<Activity>().AsQueryable();
            if (_subjectSecurity.HasAccessToSubject(ApplicationSubject.Attachments))
            {
                activities = _dbContext.Set<Activity>().Where(_ => _.CaseId == caseId && _.Attachments.Count > 0 && (!isExternal || _.Attachments.All(a => a.PublicFlag == 1)));
            }

            return activities;
        }

        public IQueryable<AttachmentItem> GetAttachments(int caseId)
        {
            var culture = _culture.Resolve();
            var external = _securityContext.User.IsExternalUser;

            var subCsr = from csr in _dbContext.Set<CaseSearchResult>()
                         where csr.CaseId == caseId
                         select csr.PriorArtId;

            var activity = _dbContext.Set<Activity>().Where(_ => _.CaseId == caseId || subCsr.Any(s => s == _.PriorartId));
            var openAction = _dbContext.Set<OpenAction>().Where(_ => _.CaseId == caseId);
            var caseEvent = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId);

            var result = (from act in activity
                          join tc in _dbContext.Set<TableCode>() on act.ActivityCategoryId equals tc.Id into tc1
                          from tc in tc1
                          join tc2 in _dbContext.Set<TableCode>() on act.ActivityTypeId equals tc2.Id into tcc
                          from tc2 in tcc.DefaultIfEmpty()
                          join at in _dbContext.Set<ActivityAttachment>() on act.Id equals at.ActivityId into at1
                          from at in at1
                          join tc3 in _dbContext.Set<TableCode>() on at.AttachmentTypeId equals tc3.Id into tccc
                          from tc3 in tccc.DefaultIfEmpty()
                          join ce in caseEvent on new { id = act.CaseId, en = act.EventId, cycle = act.Cycle } equals new { id = (int?)ce.CaseId, en = (int?)ce.EventNo, cycle = (short?)ce.Cycle } into ce1
                          from ce in ce1.DefaultIfEmpty()
                          join ev in _dbContext.Set<Event>() on ce != null ? ce.EventNo : null equals (int?)ev.Id into ev1
                          from ev in ev1.DefaultIfEmpty()
                          join ox in (from oat in openAction select new { oat.CaseId, oat.ActionId, oat.CriteriaId }).Distinct() on new { cid = act.CaseId, a = ev != null ? ev.ControllingAction : null } equals new { cid = (int?)ox.CaseId, a = ox.ActionId } into ox1
                          from ox in ox1.DefaultIfEmpty()
                          join ec in _dbContext.Set<ValidEvent>() on new { eno = ev != null ? ev.Id : (int?)null, cid = ox != null ? ox.CriteriaId : ce != null ? ce.CreatedByCriteriaKey : null } equals new { eno = ec != null ? ec.EventId : (int?)null, cid = ec != null ? ec.CriteriaId : (int?)null } into ec1
                          from ec in ec1.DefaultIfEmpty()
                          join tc4 in _dbContext.Set<TableCode>() on at.LanguageId equals tc4.Id into tcx4
                          from tc4 in tcx4.DefaultIfEmpty()
                          where !external || (at.PublicFlag ?? 0m) == 1m
                          select new AttachmentItem
                          {
                              ActivityCategory = DbFuncs.GetTranslation(tc.Name, null, tc.NameTId, culture),
                              ActivityDate = act.ActivityDate,
                              ActivityType = DbFuncs.GetTranslation(tc2.Name, null, tc2.NameTId, culture),
                              RawAttachmentName = at.AttachmentName,
                              AttachmentType = DbFuncs.GetTranslation(tc3.Name, null, tc3.NameTId, culture),
                              EventNo = act.EventId,
                              EventCycle = act.Cycle,
                              EventDescription = external ? string.Empty : ec != null && ec.Description != null ? DbFuncs.GetTranslation(ec.Description, null, ec.DescriptionTId, culture) : ev != null ? DbFuncs.GetTranslation(ev.Description, null, ev.DescriptionTId, culture) : null,
                              FilePath = at.FileName,
                              IsPublic = (at.PublicFlag ?? 0m) == 1m,
                              Language = tc4.Name,
                              PageCount = at.PageCount,
                              ActivityId = at.ActivityId,
                              SequenceNo = at.SequenceNo,
                              IsPriorArt = act.PriorartId != null
                          }).OrderByDescending(_ => _.ActivityDate)
                            .ThenBy(_ => _.RawAttachmentName);

            return result;
        }
    }

    public class AttachmentItem
    {
        public int ActivityId { get; set; }
        public int SequenceNo { get; set; }
        public string ActivityCategory { get; set; }
        public DateTime? ActivityDate { get; set; }
        public string ActivityType { get; set; }
        public string RawAttachmentName { get; set; }
        public string AttachmentName => GetAttachmentNameFromFilePath();
        public string AttachmentType { get; set; }

        [JsonIgnore]
        public int? EventNo { get; set; }

        public short? EventCycle { get; set; }
        public string EventDescription { get; set; }
        public string FilePath { get; set; }
        public bool IsPublic { get; set; }
        public string Language { get; set; }
        public int? PageCount { get; set; }
        public bool IsPriorArt { get; set; }

        string GetAttachmentNameFromFilePath()
        {
            return string.IsNullOrWhiteSpace(RawAttachmentName) ? FilePath.Substring(FilePath.LastIndexOf(@"\", StringComparison.Ordinal) + 1) : RawAttachmentName;
        }
    }
}