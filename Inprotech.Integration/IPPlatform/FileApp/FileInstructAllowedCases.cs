using System;
using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Integration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.IPPlatform.FileApp
{
    public interface IFileInstructAllowedCases
    {
        IQueryable<FileInstructAllowedCase> Retrieve(FileSettings settings = null);
    }

    public class FileInstructAllowedCases : IFileInstructAllowedCases
    {
        readonly IDbContext _dbContext;

        public FileInstructAllowedCases(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<FileInstructAllowedCase> Retrieve(FileSettings settings)
        {
            if (!settings.IsEnabled)
            {
                return Enumerable.Empty<FileInstructAllowedCase>().AsQueryable();
            }

            var fc = _dbContext.Set<FileCase>();

            var postPct = EligibleForPatentPostPct(settings);

            var directPatent = EligibleForDirectPatent(settings);

            var trademarks = EligibleForTrademarkDirect(settings);

            var all = postPct.Union(directPatent).Union(trademarks);

            return from e in _dbContext.FilterEligibleCasesForComparison("FILE")
                   join a in all on e.CaseKey equals a.CaseId into a1
                   from a in a1
                   join f in fc on new {a.CaseId, a.IpType, p = (int?) a.ParentCaseId} equals new {f.CaseId, f.IpType, p = f.ParentCaseId} into f1
                   from f in f1.DefaultIfEmpty()
                   select new FileInstructAllowedCase
                   {
                       ParentCaseId = a.ParentCaseId,
                       CaseId = a.CaseId,
                       CountryCode = a.CountryCode,
                       IpType = a.IpType,
                       EarliestPriority = a.EarliestPriority,
                       Filed = f != null
                   };
        }

        IQueryable<FileInstructAllowedCase> EligibleForPatentPostPct(FileSettings settings)
        {
            var designatedCountries = _dbContext.Set<RelatedCase>().ByRelationship(settings.DesignatedCountryRelationship);

            var patents = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().ByPropertyType(KnownPropertyTypes.Patent);

            return from c in patents
                   join rdc in designatedCountries on new {a = (int?) c.Id} equals new {a = rdc.RelatedCaseId} into rdc1
                   from rdc in rdc1
                   select new FileInstructAllowedCase
                   {
                       ParentCaseId = rdc.CaseId,
                       CaseId = c.Id,
                       CountryCode = c.Country.Id,
                       IpType = IpTypes.PatentPostPct,
                       EarliestPriority = null,
                       Filed = false
                   };
        }

        IQueryable<FileInstructAllowedCase> EligibleForDirectPatent(FileSettings settings)
        {
            var fromEvent = (from cr in _dbContext.Set<CaseRelation>()
                             where cr.Relationship == settings.EarliestPriorityRelationship
                             select cr.DisplayEventId ?? cr.FromEventId)
                .SingleOrDefault();

            var earliestPriority = _dbContext.Set<RelatedCase>().ByRelationship(settings.EarliestPriorityRelationship);

            var earliestPriorityDate = _dbContext.Set<CaseEvent>().Where(_ => _.Cycle == 1 && _.EventNo == fromEvent);

            var patents = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().ByPropertyType(KnownPropertyTypes.Patent);

            return from c in patents
                   join rep in earliestPriority on new {a = c.Id} equals new {a = rep.CaseId} into rep1
                   from rep in rep1
                   join ce in earliestPriorityDate on rep.RelatedCaseId equals ce.CaseId into ce1
                   from ce in ce1.DefaultIfEmpty()
                   where rep.RelatedCaseId != null
                   select new FileInstructAllowedCase
                   {
                       ParentCaseId = (int) rep.RelatedCaseId,
                       CaseId = c.Id,
                       CountryCode = c.Country.Id,
                       IpType = IpTypes.DirectPatent,
                       EarliestPriority = ce != null ? ce.EventDate : null,
                       Filed = false
                   };
        }

        IQueryable<FileInstructAllowedCase> EligibleForTrademarkDirect(FileSettings settings)
        {
            var fromEvent = (from cr in _dbContext.Set<CaseRelation>()
                             where cr.Relationship == settings.EarliestPriorityRelationship
                             select cr.DisplayEventId ?? cr.FromEventId)
                .SingleOrDefault();

            var earliestPriority = _dbContext.Set<RelatedCase>().ByRelationship(settings.EarliestPriorityRelationship);

            var earliestPriorityDate = _dbContext.Set<CaseEvent>().Where(_ => _.Cycle == 1 && _.EventNo == fromEvent);

            var trademarks = _dbContext.Set<InprotechKaizen.Model.Cases.Case>().ByPropertyType(KnownPropertyTypes.TradeMark);

            return from c in trademarks
                   join rep in earliestPriority on new {a = c.Id} equals new {a = rep.CaseId} into rep1
                   from rep in rep1
                   join ce in earliestPriorityDate on rep.RelatedCaseId equals ce.CaseId into ce1
                   from ce in ce1.DefaultIfEmpty()
                   where rep.RelatedCaseId != null
                   select new FileInstructAllowedCase
                   {
                       ParentCaseId = (int) rep.RelatedCaseId,
                       CaseId = c.Id,
                       CountryCode = c.Country.Id,
                       IpType = IpTypes.TrademarkDirect,
                       EarliestPriority = ce != null ? ce.EventDate : null,
                       Filed = false
                   };
        }
    }

    public class FileInstructAllowedCase
    {
        public int ParentCaseId { get; set; }

        public int CaseId { get; set; }

        public string CountryCode { get; set; }

        public string IpType { get; set; }

        public bool Filed { get; set; }

        public DateTime? EarliestPriority { get; set; }
    }

    public class FileInstructAllowedCaseDetail : FileInstructAllowedCase
    {
        public string Irn { get; set; }

        public string LocalClasses { get; set; }
    }

    public static class FileInstructAllowedCasesExtension
    {
        public static FileInstructAllowedCase Earliest(this FileInstructAllowedCase[] allowedCases)
        {
            var pct = allowedCases.FirstOrDefault(_ => _.IpType == IpTypes.PatentPostPct);
            return pct ?? (from d in allowedCases
                           where d.EarliestPriority != null
                           orderby d.EarliestPriority
                           select d).FirstOrDefault();
        }

        public static FileInstructAllowedCaseDetail Earliest(this FileInstructAllowedCaseDetail[] allowedCases)
        {
            var pct = allowedCases.FirstOrDefault(_ => _.IpType == IpTypes.PatentPostPct);
            return pct ?? (from d in allowedCases
                           where d.EarliestPriority != null
                           orderby d.EarliestPriority
                           select d).FirstOrDefault();
        }
    }
}