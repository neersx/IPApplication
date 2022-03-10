using System;
using System.Linq;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

namespace InprotechKaizen.Model.Components.Configuration
{
    public interface ILastInternalCodeGenerator
    {
        int GenerateLastInternalCode(string tableName);

        int GenerateNegativeLastInternalCode(string tableName);
    }

    public class LastInternalCodeGenerator : ILastInternalCodeGenerator
    {
        readonly IDbContext _dbContext;

        public LastInternalCodeGenerator(IDbContext dbContext)
        {
            _dbContext = dbContext;
        }

        public int GenerateLastInternalCode(string tableName)
        {
            if (string.IsNullOrWhiteSpace(tableName)) throw new ArgumentNullException(nameof(tableName));

            tableName = tableName.ToUpper();

            var internalCode = _dbContext.Set<LastInternalCode>();

            var last = internalCode.FirstOrDefault(_ => _.TableName == tableName)
                       ?? _dbContext.Set<LastInternalCode>()
                                    .Add(new LastInternalCode(tableName.ToUpper())
                                    {
                                        InternalSequence = 0
                                    });

            if (tableName == KnownInternalCodeTable.Policing || tableName == KnownInternalCodeTable.PolicingBatch)
            {
                last.InternalSequence = _dbContext.Set<PolicingRequest>()
                                                  .DefaultIfEmpty()
                                                  .Max(_ => _.BatchNumber ?? 0);
            }

            last.InternalSequence++;

            _dbContext.SaveChanges();

            return _dbContext.Reload(last).InternalSequence;
        }

        public int GenerateNegativeLastInternalCode(string tableName)
        {
            if (string.IsNullOrWhiteSpace(tableName)) throw new ArgumentNullException(nameof(tableName));

            tableName = tableName.ToUpper();

            var internalCode = _dbContext.Set<LastInternalCode>();

            var last = internalCode.FirstOrDefault(_ => _.TableName == tableName)
                       ?? _dbContext.Set<LastInternalCode>()
                                    .Add(new LastInternalCode(tableName.ToUpper())
                                    {
                                        InternalSequence = 0
                                    });

            last.InternalSequence--;

            _dbContext.SaveChanges();

            return _dbContext.Reload(last).InternalSequence;
        }
    }
}