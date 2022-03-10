using System.Collections.Generic;
using System.Linq;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.InproDoc
{
    public interface IDocItemCommand
    {
        IEnumerable<ReferencedDataItem> ListDocItems(string culture);
    }

    public class DocItemCommand : IDocItemCommand
    {
        readonly IDbContext _dbContext;

        public DocItemCommand(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }
        
        public IEnumerable<ReferencedDataItem> ListDocItems(string culture)
        {
            return from i in _dbContext.Set<DocItem>()
                   orderby i.Name
                   select new ReferencedDataItem
                   {
                       ItemKey = i.Id,
                       ItemName = i.Name,
                       ItemDescription = DbFuncs.GetTranslation(i.Description, null, i.ItemDescriptionTId, culture),
                       EntryPointUsage = i.EntryPointUsage
                   };
        }
    }
}