using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Localisation;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseRenewalDetails
    {
        Task<CaseRenewalData> GetRenewalDetails(int caseId, int screenCriteriaKey);
    }

    public class CaseRenewalDetails : ICaseRenewalDetails
    {
        readonly ICaseStandingInstructions _caseStandingInstructions;
        readonly ICaseViewNamesProvider _caseViewNamesProvider;
        readonly ICriteriaReader _criteriaReader;
        readonly IDbContext _dbContext;
        readonly IDocItemRunner _docItemRunner;
        readonly INextRenewalDatesResolver _nextRenewalDatesResolver;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly ISiteControlReader _siteControls;
        readonly IUserFilteredTypes _userFilteredTypes;

        public CaseRenewalDetails(IDbContext dbContext,
                                  INextRenewalDatesResolver nextRenewalDatesResolver,
                                  ISiteControlReader siteControls,
                                  IPreferredCultureResolver preferredCultureResolver,
                                  ISecurityContext securityContext,
                                  ICriteriaReader criteriaReader,
                                  ICaseStandingInstructions caseStandingInstructions,
                                  ICaseViewNamesProvider caseViewNamesProvider,
                                  IUserFilteredTypes userFilteredTypes,
                                  IDocItemRunner docItemRunner)
        {
            _dbContext = dbContext;
            _nextRenewalDatesResolver = nextRenewalDatesResolver;
            _siteControls = siteControls;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _criteriaReader = criteriaReader;
            _caseStandingInstructions = caseStandingInstructions;
            _caseViewNamesProvider = caseViewNamesProvider;
            _userFilteredTypes = userFilteredTypes;
            _docItemRunner = docItemRunner;
        }

        public async Task<CaseRenewalData> GetRenewalDetails(int caseId, int screenCriteriaKey)
        {
            var culture = _preferredCultureResolver.Resolve();

            var isExternalUser = _securityContext.User.IsExternalUser;

            var sc = _siteControls.ReadMany<bool?>(SiteControls.ClientsUnawareofCPA, SiteControls.RenewalNameTypeOptional);
            var clientsUnawareOfCpaValue = sc.Get(SiteControls.ClientsUnawareofCPA);
            var renewalNameTypeOptional = sc.Get(SiteControls.RenewalNameTypeOptional);

            var tableCodesForRenewType = _dbContext.Set<TableCode>()
                                                   .Where(_ => _.TableTypeId == (short) TableTypes.RenewalType);
            var tableCodesForStopPayReason = _dbContext.Set<TableCode>()
                                                       .Where(_ => _.TableTypeId == (short) TableTypes.CpaStopPayReason68);

            var cases = _dbContext.Set<Case>()
                                  .Where(_ => _.Id == caseId);

            var caseDetails = await (from c in cases
                                     join t in tableCodesForRenewType on c.Property.RenewalType equals t.Id into tablecodeDetails
                                     from tcrt in tablecodeDetails.DefaultIfEmpty()
                                     join s in tableCodesForStopPayReason on c.StopPayReason equals s.UserCode into stopPayReason
                                     from tcsp in stopPayReason.DefaultIfEmpty()
                                     select new
                                     {
                                         c.Irn,
                                         c.ExtendedRenewals,
                                         Name = tcrt != null ? DbFuncs.GetTranslation(tcrt.Name, null, tcrt.NameTId, culture) : null,
                                         ReportToThirdParty = c.ReportToThirdParty.HasValue && c.ReportToThirdParty.Value == 1m,
                                         StopPayReason = tcsp != null ? DbFuncs.GetTranslation(tcsp.Name, null, tcsp.NameTId, culture) : null,
                                         c.CaseEvents,
                                         c.Property.RenewalNotes
                                     }).SingleOrDefaultAsync();

            var nextRenewal = await _nextRenewalDatesResolver.Resolve(caseId);
            var cpaRenewalDates = await GetCpaRenewalDates(caseId);

            var relevantDates = await GetRelevantDates(culture, caseId, nextRenewal?.NextRenewalDate);
            var caseStandingInstructions = await GetCaseRenewalStandingInstructions(caseId);

            var caseRenewalNames = await GetCaseRenewalNames(caseId, screenCriteriaKey, renewalNameTypeOptional);

            return new CaseRenewalData
            {
                NextRenewalDate = nextRenewal?.NextRenewalDate,
                RenewalYear = nextRenewal?.AgeOfCase,
                ExtendedRenewalYears = caseDetails?.ExtendedRenewals,
                RenewalType = caseDetails?.Name,
                ReportToCpa = caseDetails != null && caseDetails.ReportToThirdParty,
                StartPaying = cpaRenewalDates.CpaStartPayDate,
                StopPaying = cpaRenewalDates.CpaStopPayDate,
                ReasonToStopPay = caseDetails?.StopPayReason,
                LastExtracted = cpaRenewalDates.LastExtractedDate,
                LastExtractedNo = cpaRenewalDates.LastExtractedNo,
                LastCpaEvent = cpaRenewalDates.LastCPAEvent,
                CpaEventCode = cpaRenewalDates.CpaEventCode,
                PortfolioDate = cpaRenewalDates.PortfolioDate,
                CpaRenewalDate = nextRenewal?.CpaRenewalDate,
                IsExternalUser = isExternalUser,
                ClientsUnawareOfCpa = clientsUnawareOfCpaValue,
                RenewalNotes = caseDetails?.RenewalNotes,
                RelevantDates = relevantDates,
                StandingInstructions = caseStandingInstructions,
                RenewalNames = caseRenewalNames,
                IpplatformRenewLink = GetIpPlatformRenewLink(caseDetails?.Irn)
            };
        }

        async Task<InterimCpaDetails> GetCpaRenewalDates(int caseId)
        {
            var sc = _siteControls.ReadMany<int?>(SiteControls.CPADate_Start, SiteControls.CPADate_Stop);
            var cpaStartPayEventNo = sc.Get(SiteControls.CPADate_Start);
            var cpaStopPayEventNo = sc.Get(SiteControls.CPADate_Stop);
            var cases = _dbContext.Set<Case>();
            var events = _dbContext.Set<CaseEvent>();

            var lastExtracted = from c in _dbContext.Set<CpaSend>()
                                group c by c.CaseId
                                into cg
                                select new
                                {
                                    MaxBatch = cg.DefaultIfEmpty().Max(_ => _.BatchNo),
                                    CaseId = cg.Key
                                };

            var interim = await (from c in cases
                                 join cpaStart in events on new {CaseId = c.Id, EventNo = cpaStartPayEventNo, Cycle = (short) 1} equals new {cpaStart.CaseId, EventNo = (int?) cpaStart.EventNo, cpaStart.Cycle} into cpaStart1
                                 from cpaStart in cpaStart1.DefaultIfEmpty()
                                 join cpaStop in events on new {CaseId = c.Id, EventNo = cpaStopPayEventNo, Cycle = (short) 1} equals new {cpaStop.CaseId, EventNo = (int?) cpaStop.EventNo, cpaStop.Cycle} into cpaStop1
                                 from cpaStop in cpaStop1.DefaultIfEmpty()
                                 join e1 in lastExtracted on c.Id equals e1.CaseId into e11
                                 from e1 in e11.DefaultIfEmpty()
                                 join lastExtractedRow in _dbContext.Set<CpaSend>() on new
                                     {
                                         CaseId = e1 != null ? e1.CaseId : null,
                                         BatchNo = e1 != null ? (int?) e1.MaxBatch : null
                                     }
                                     equals new {lastExtractedRow.CaseId, BatchNo = (int?) lastExtractedRow.BatchNo} into cpaSend1
                                 from lastExtractedRow in cpaSend1.DefaultIfEmpty()
                                 where c.Id == caseId
                                 select new InterimCpaDetails
                                 {
                                     CpaStartPayDate = cpaStart != null ? cpaStart.EventDate ?? cpaStart.EventDueDate : null,
                                     CpaStopPayDate = cpaStop != null ? cpaStop.EventDate ?? cpaStop.EventDueDate : null,
                                     LastExtractedDate = lastExtractedRow != null ? lastExtractedRow.BatchDate : null,
                                     LastExtractedNo = lastExtractedRow != null ? (int?) lastExtractedRow.BatchNo : null
                                 }).SingleAsync();

            var lastCpaEvent = await (from c in _dbContext.Set<CpaEvent>()
                                      where c.CaseId == caseId
                                      orderby c.RenewalEventDate descending
                                      select new
                                      {
                                          c.RenewalEventDate,
                                          c.EventCode
                                      }).FirstOrDefaultAsync();

            if (lastCpaEvent != null)
            {
                interim.CpaEventCode = lastCpaEvent.EventCode;
                interim.LastCPAEvent = lastCpaEvent.RenewalEventDate;
            }

            var portfolio = await (from c in _dbContext.Set<CpaPortfolio>()
                                   where c.CaseId == caseId
                                   let orderIndicator = c.StatusIndicator == "L" ? 1 : c.StatusIndicator == "T" ? 2 : 3
                                   orderby orderIndicator descending, c.Id
                                   select c.DateOfPortfolioList).FirstOrDefaultAsync();

            interim.PortfolioDate = portfolio;

            return interim;
        }

        public async Task<IEnumerable<RelevantDate>> GetRelevantDates(string culture, int caseId, DateTime? nextRenewalDate)
        {
            var userId = _securityContext.User.Id;
            var isExternalUser = _securityContext.User.IsExternalUser;

            var displayActionCode = _siteControls.Read<string>(SiteControls.RenewalDisplayActionCode);
            if (string.IsNullOrWhiteSpace(displayActionCode))
            {
                return Enumerable.Empty<RelevantDate>();
            }

            _criteriaReader.TryGetEventControl(caseId, displayActionCode, out var criteriaId);
            if (!criteriaId.HasValue)
            {
                return Enumerable.Empty<RelevantDate>();
            }

            var validEvents = _dbContext.Set<ValidEvent>()
                                        .Where(_ => _.CriteriaId == criteriaId.Value);

            var relevantEvents = await (from ce in _dbContext.Set<CaseEvent>()
                                        join ve in validEvents on ce.EventNo equals ve.EventId
                                        join fue in _dbContext.FilterUserEvents(userId, culture, true)
                                            on ce.EventNo equals fue.EventNo into fue1
                                        from fue in fue1.DefaultIfEmpty()
                                        where ce.Cycle == 1 && ce.CaseId == caseId && (isExternalUser && fue != null || !isExternalUser)
                                        orderby ve.DisplaySequence
                                        select new RelevantDate
                                        {
                                            EventNo = ce.EventNo,
                                            EventDescription = DbFuncs.GetTranslation(ve.Description, null, ve.DescriptionTId, culture),
                                            EventDate = ce.EventDate ?? ce.EventDueDate,
                                            IsOccurred = ce.EventDate != null
                                        }).ToArrayAsync();

            var nextRenewalEvent = relevantEvents.SingleOrDefault(_ => _.EventNo == (int) KnownEvents.NextRenewalDate);
            if (nextRenewalEvent != null)
            {
                nextRenewalEvent.EventDate = nextRenewalDate;
                nextRenewalEvent.IsOccurred = false;
            }

            return relevantEvents;
        }

        async Task<IEnumerable<CaseStandingInstruction>> GetCaseRenewalStandingInstructions(int caseId)
        {
            var caseStandingInstructions = (await _caseStandingInstructions.GetStandingInstructions(caseId))
                .ToDictionary(
                              k => k.InstructionTypeCode,
                              v => (Description: v.Description, InstructionTypeDesc: v.InstructionTypeDesc));

            return (await (from v in _dbContext.Set<ValidEvent>()
                           join c in _dbContext.Set<Criteria>() on v.CriteriaId equals c.Id
                           join a in _dbContext.Set<Action>().Where(ac => ac.ActionType == 1) on c.ActionId equals a.Code
                           join ui in _userFilteredTypes.InstructionTypes() on v.InstructionType equals ui.Code
                           where caseStandingInstructions.Keys.Contains(v.InstructionType)
                           select v.InstructionType)
                          .Distinct()
                          .ToListAsync())
                .Select(_ => new CaseStandingInstruction
                {
                    InstructionType = _,
                    Instruction = caseStandingInstructions[_].Description,
                    InstructionTypeDescription = caseStandingInstructions[_].InstructionTypeDesc
                });
        }

        async Task<IEnumerable<CaseViewName>> GetCaseRenewalNames(int caseId, int screenCriteriaKey, bool? renewalNameTypeOptional)
        {
            string[] renewalNameTypes = {KnownNameTypes.RenewalsInstructor, KnownNameTypes.RenewalsDebtor, KnownNameTypes.RenewalAgent};
            string[] nonRenewalNameTypes = {KnownNameTypes.Instructor, KnownNameTypes.Debtor, KnownNameTypes.Agent};

            var caseRenewalNames = await _caseViewNamesProvider.GetNames(caseId, renewalNameTypes.Concat(nonRenewalNameTypes).ToArray(), screenCriteriaKey);

            IEnumerable<CaseViewName> caseViewNames = caseRenewalNames.ToList();

            var renewalsInstructorExists = caseViewNames.Any(_ => _.TypeId == KnownNameTypes.RenewalsInstructor);
            var renewalsDebtorExists = caseViewNames.Any(_ => _.TypeId == KnownNameTypes.RenewalsDebtor);
            var renewalsAgentExists = caseViewNames.Any(_ => _.TypeId == KnownNameTypes.RenewalAgent);

            if (!renewalNameTypeOptional.GetValueOrDefault() && !renewalsInstructorExists && !renewalsDebtorExists && !renewalsAgentExists) return null;

            var excludeNameTypes = new List<string>();

            if (!renewalNameTypeOptional.GetValueOrDefault())
            {
                return caseViewNames.Where(_ => renewalNameTypes.Contains(_.TypeId));
            }

            if (renewalsInstructorExists)
            {
                excludeNameTypes.Add(KnownNameTypes.Instructor);
            }

            if (renewalsDebtorExists)
            {
                excludeNameTypes.Add(KnownNameTypes.Debtor);
            }

            if (renewalsAgentExists)
            {
                excludeNameTypes.Add(KnownNameTypes.Agent);
            }

            return caseViewNames.Where(_ => !excludeNameTypes.Contains(_.TypeId));
        }

        string GetIpPlatformRenewLink(string irn)
        {
            string link;

            if (string.IsNullOrWhiteSpace(irn))
            {
                return null;
            }

            try
            {
                var parameters = DefaultDocItemParameters.ForDocItemSqlQueries(irn, _securityContext.User.Id);
                link = _docItemRunner.Run("LINK_IPPLATFORM_RENEW", parameters).ScalarValueOrDefault<string>();
            }
            catch (ArgumentException)
            {
                return null;
            }

            return string.IsNullOrWhiteSpace(link) ? null : link;
        }

        public class InterimCpaDetails
        {
            public DateTime? CpaStartPayDate { get; set; }
            public DateTime? CpaStopPayDate { get; set; }
            public DateTime? LastExtractedDate { get; set; }
            public int? LastExtractedNo { get; set; }
            public DateTime? LastCPAEvent { get; set; }
            public string CpaEventCode { get; set; }
            public DateTime? PortfolioDate { get; set; }
        }
    }

    public class CaseRenewalData
    {
        public DateTime? NextRenewalDate { get; set; }
        public string RenewalType { get; set; }
        public int? RenewalYear { get; set; }
        public int? ExtendedRenewalYears { get; set; }
        public bool ReportToCpa { get; set; }
        public DateTime? StartPaying { get; set; }
        public DateTime? StopPaying { get; set; }
        public string ReasonToStopPay { get; set; }
        public DateTime? LastExtracted { get; set; }
        public int? LastExtractedNo { get; set; }
        public DateTime? LastCpaEvent { get; set; }
        public string CpaEventCode { get; set; }
        public DateTime? PortfolioDate { get; set; }
        public DateTime? CpaRenewalDate { get; set; }
        public bool IsExternalUser { get; set; }
        public bool? ClientsUnawareOfCpa { get; set; }
        public string RenewalNotes { get; set; }
        public IEnumerable<RelevantDate> RelevantDates { get; set; }
        public IEnumerable<CaseStandingInstruction> StandingInstructions { get; set; }
        public IEnumerable<CaseViewName> RenewalNames { get; set; }
        public string IpplatformRenewLink { get; set; }
    }

    public class RelevantDate
    {
        [JsonIgnore]
        public int EventNo { get; set; }

        public DateTime? EventDate { get; set; }

        public string EventDescription { get; set; }

        public bool IsOccurred { get; set; } = true;
    }

    public class CaseStandingInstruction
    {
        public string InstructionTypeDescription { get; set; }
        public string Instruction { get; set; }

        [JsonIgnore]
        public string InstructionType { get; set; }
    }
}