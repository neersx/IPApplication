using System.Linq;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.SchemaMapping
{
    public interface ISyncToTableCodes
    {
        void Sync();
    }

    internal class SyncToTableCodes : ISyncToTableCodes
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public SyncToTableCodes(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public void Sync()
        {
            var mappings = _dbContext.Set<InprotechKaizen.Model.SchemaMappings.SchemaMapping>()
                                     .Select(_ => new
                                     {
                                         _.Id,
                                         _.Name
                                     }).ToArray();

            var tableCodes = _dbContext.Set<TableCode>()
                                       .Where(_ => _.TableTypeId == (short) TableTypes.SchemaMapping)
                                       .ToList();

            foreach (var mapping in mappings)
            {
                var existing = tableCodes.SingleOrDefault(tableCode => mapping.Id.ToString() == tableCode.UserCode);

                if (existing == null)
                {
                    var id = _lastInternalCodeGenerator.GenerateLastInternalCode(KnownInternalCodeTable.TableCodes);
                    _dbContext.Set<TableCode>()
                              .Add(new TableCode(id, (short) TableTypes.SchemaMapping, mapping.Name, mapping.Id.ToString()));
                }
                else
                {
                    existing.Name = mapping.Name;
                    tableCodes.Remove(existing);
                }
            }

            foreach (var tableCode in tableCodes)
                _dbContext.Set<TableCode>().Remove(tableCode);
        }
    }
}