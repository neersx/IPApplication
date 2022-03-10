using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Services.Pdf
{
    public interface IFormFieldsResolver
    {
        Task<IEnumerable<FieldItem>> Resolve(int documentId, string culture);
    }

    public class FormFieldsResolver : IFormFieldsResolver
    {
        readonly IDbContext _dbContext;

        public FormFieldsResolver(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public async Task<IEnumerable<FieldItem>> Resolve(int documentId, string culture)
        {
            return await (from ff in _dbContext.Set<FormFields>()
                          join i in _dbContext.Set<DocItem>() on ff.ItemId equals i.Id into i1
                          from di in i1.DefaultIfEmpty()
                          where ff.DocumentId == documentId
                          orderby ff.FieldName
                          select new FieldItem
                          {
                              DocumentId = ff.DocumentId,
                              FieldName = ff.FieldName,
                              FieldType = (FieldType) ff.FieldType,
                              FieldDescription = DbFuncs.GetTranslation(ff.FieldDescription, null, null, culture),
                              ItemId = ff.ItemId,
                              ItemName = di.Name,
                              ItemDescription = di == null ? string.Empty : DbFuncs.GetTranslation(di.Description, null, di.ItemDescriptionTId, culture),
                              ItemParameter = ff.ItemParameter,
                              ResultSeparator = ff.ResultSeperator
                          }).ToArrayAsync();
        }
    }
}