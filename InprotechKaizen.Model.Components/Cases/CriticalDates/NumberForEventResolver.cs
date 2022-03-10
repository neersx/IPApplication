using System.Linq;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Cases.CriticalDates
{
    public interface INumberForEventResolver
    {
        IQueryable<OfficialNumberForEvent> Resolve(int caseId);
    }

    public class NumberForEventResolver : INumberForEventResolver
    {
        readonly IDbContext _dbContext;

        public NumberForEventResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public IQueryable<OfficialNumberForEvent> Resolve(int caseId)
        {
            var relatedEvent = from nt in _dbContext.Set<NumberType>()
                               join o in _dbContext.Set<OfficialNumber>() on nt.NumberTypeCode equals o.NumberTypeId into o1
                               from o in o1
                               where o.CaseId == caseId && o.IsCurrent == 1
                               select new
                               {
                                   nt.RelatedEventId,
                                   nt.DisplayPriority
                               };
            
            return from o in _dbContext.Set<OfficialNumber>()
                   join nt in _dbContext.Set<NumberType>() on o.NumberTypeId equals nt.NumberTypeCode into nt1
                   from nt in nt1
                   where o.IsCurrent == 1
                         && o.CaseId == caseId
                         && nt.IssuedByIpOffice
                         && nt.RelatedEventId != null
                         && nt.DisplayPriority == (from n in relatedEvent
                                                   where n.RelatedEventId == nt.RelatedEventId
                                                   select n.DisplayPriority).Min()
                   select new OfficialNumberForEvent
                   {
                       EventNo = (int) nt.RelatedEventId,
                       NumberType = nt.NumberTypeCode,
                       OfficialNumber = o.Number,
                       DataItemId = nt.DocItemId
                   };
        }
    }
    
    public class OfficialNumberForEvent
    {
        public int EventNo { get; set; }

        public string NumberType { get; set; }

        public string OfficialNumber { get; set; }

        public int? DataItemId { get; set; }
    }
}