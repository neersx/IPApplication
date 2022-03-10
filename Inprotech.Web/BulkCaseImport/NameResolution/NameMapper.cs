using System;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.Extensions;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.BulkCaseImport.NameResolution
{
    public interface INameMapper
    {
        void Map(int batchId, int unresolvedNameId, int mapNameId);
    }

    public class NameMapper : INameMapper
    {
        readonly IDbContext _dbContext;

        public NameMapper(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _dbContext = dbContext;
        }

        public void Map(int batchId, int unresolvedNameId, int mapNameId)
        {
            var sender = GetSender(batchId);
            var unresolvedName = _dbContext.Set<EdeUnresolvedName>().Single(n => n.Id == unresolvedNameId);

            using (var ts = _dbContext.BeginTransaction())
            {
                var externalNameId = AddExternalName(sender.Id, unresolvedName);

                MapExternalName(externalNameId, mapNameId);

                MapNameInBatch(batchId, unresolvedNameId, mapNameId);

                _dbContext.Set<EdeUnresolvedName>().Remove(unresolvedName);
                _dbContext.SaveChanges();

                ts.Complete();
            }
        }

        void MapNameInBatch(int batchId, int unresolvedNameId, int mapNameId)
        {
            foreach (var m in _dbContext.Set<EdeAddressBook>()
                .Where(b => b.BatchId == batchId && b.UnresolvedNameId == unresolvedNameId).ToArray())
            {
                m.NameId = mapNameId;
                m.UnresolvedNameId = null;
            }
        }

        Name GetSender(int batchId)
        {
            var senderDetails = _dbContext.Set<EdeSenderDetails>()
                .Include(s => s.TransactionHeader)
                .Single(s => s.TransactionHeader.BatchId == batchId);

            return _dbContext.Set<NameAlias>().EdeSenderNameFor(senderDetails.Sender);
        }

        int AddExternalName(int dataSourceId, EdeUnresolvedName un)
        {
            var externalName =
                _dbContext.Set<ExternalName>().Add(new ExternalName
                {
                    DataSourceNameId = dataSourceId,
                    Email = un.Email,
                    EntityType = un.EntityType,
                    ExternalNameCode = un.SenderNameIdentifier,
                    ExtName = un.Name,
                    FirstName = un.FirstName,
                    NameType = un.NameType,
                    Fax = un.Fax,
                    Phone = un.Phone,
                    ExternalNameAddress = new ExternalNameAddress
                    {
                        Address = un.AddressLine,
                        City = un.City,
                        State = un.State,
                        PostCode = un.PostCode,
                        Country = un.CountryCode
                    }
                });

            _dbContext.SaveChanges();

            return externalName.Id;
        }

        void MapExternalName(int externalNameId, int inproNameId)
        {
            _dbContext.Set<ExternalNameMapping>().Add(new ExternalNameMapping
            {
                ExternalNameId = externalNameId,
                InproNameId = inproNameId
            });
        }
    }
}