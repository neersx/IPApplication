using System;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Accounting.OpenItem;
using InprotechKaizen.Model.Components.Configuration;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.Persistence
{
    public interface IExactNameAddressSnapshot
    {
        Task<int> Derive(NameAddressSnapshotParameter parameter);
    }

    public class ExactNameAddressSnapshot : IExactNameAddressSnapshot
    {
        readonly IDbContext _dbContext;
        readonly ILastInternalCodeGenerator _lastInternalCodeGenerator;

        public ExactNameAddressSnapshot(IDbContext dbContext, ILastInternalCodeGenerator lastInternalCodeGenerator)
        {
            _dbContext = dbContext;
            _lastInternalCodeGenerator = lastInternalCodeGenerator;
        }

        public async Task<int> Derive(NameAddressSnapshotParameter parameter)
        {
            if (parameter == null) throw new ArgumentNullException(nameof(parameter));

            var (found, snapshotId) = parameter.SnapshotId switch
            {
                null => await HasExactMatchingNameAddressSnapshot(parameter),
                _ => await HasUpdatedNameAddressSnapshotIfReferencedOnlyOnce(parameter)
            };

            return found
                ? (int)snapshotId
                : await CreateNewNameAddressSnapshot(parameter);
        }

        async Task<int> CreateNewNameAddressSnapshot(NameAddressSnapshotParameter parameter)
        {
            var newSnapshotId = _lastInternalCodeGenerator.GenerateLastInternalCode("NAMEADDRESSSNAP");

            _dbContext.Set<NameAddressSnapshot>()
                      .Add(new NameAddressSnapshot
                      {
                          NameSnapshotId = newSnapshotId,
                          NameId = parameter.AccountDebtorId,
                          FormattedName = parameter.FormattedName,
                          FormattedAddress = parameter.FormattedAddress,
                          FormattedAttention = parameter.FormattedAttention,
                          FormattedReference = parameter.FormattedReference,
                          AttentionNameId = parameter.AttentionNameId,
                          AddressCode = parameter.AddressId,
                          ReasonCode = parameter.AddressChangeReasonId
                      });

            await _dbContext.SaveChangesAsync();

            return newSnapshotId;
        }

        async Task<(bool Found, int? SnapshotId)> HasUpdatedNameAddressSnapshotIfReferencedOnlyOnce(NameAddressSnapshotParameter parameter)
        {
            if (await (from openItem in _dbContext.Set<OpenItem>()
                       where openItem.NameSnapshotId == parameter.SnapshotId
                       select openItem.NameSnapshotId).CountAsync() != 1)
            {
                return (false, null);
            }

            await _dbContext.UpdateAsync(from nas in _dbContext.Set<NameAddressSnapshot>()
                                         where nas.NameSnapshotId == parameter.SnapshotId
                                         select nas,
                                         _ => new NameAddressSnapshot
                                         {
                                             NameId = parameter.AccountDebtorId,
                                             FormattedName = parameter.FormattedName,
                                             FormattedAddress = parameter.FormattedAddress,
                                             FormattedAttention = parameter.FormattedAttention,
                                             FormattedReference = parameter.FormattedReference,
                                             AttentionNameId = parameter.AttentionNameId,
                                             AddressCode = parameter.AddressId,
                                             ReasonCode = parameter.AddressChangeReasonId
                                         });

            return (true, parameter.SnapshotId);
        }

        async Task<(bool Found, int? SnapshotId)> HasExactMatchingNameAddressSnapshot(NameAddressSnapshotParameter parameter)
        {
            var shortlist = await (
                from nas in _dbContext.Set<NameAddressSnapshot>()
                where nas.FormattedName == parameter.FormattedName &&
                      nas.FormattedAddress == parameter.FormattedAddress &&
                      nas.FormattedAttention == parameter.FormattedAttention &&
                      nas.FormattedReference == parameter.FormattedReference &&
                      nas.AddressCode == parameter.AddressId &&
                      nas.AttentionNameId == parameter.AttentionNameId &&
                      nas.ReasonCode == parameter.AddressChangeReasonId
                select nas).ToArrayAsync();

            // Force Case Sensitive Compare on Case Insensitive SQL Server Collation
            var snapshotId = (from nas in shortlist
                              where nas.FormattedName == parameter.FormattedName &&
                                    nas.FormattedAddress == parameter.FormattedAddress &&
                                    nas.FormattedAttention == parameter.FormattedAttention &&
                                    nas.FormattedReference == parameter.FormattedReference &&
                                    nas.AddressCode == parameter.AddressId &&
                                    nas.AttentionNameId == parameter.AttentionNameId &&
                                    nas.ReasonCode == parameter.AddressChangeReasonId
                              select nas).FirstOrDefault()?.NameSnapshotId;

            return (snapshotId != null, snapshotId);
        }
    }

    public class NameAddressSnapshotParameter
    {
        string _formattedName;
        string _formattedAddress;
        string _formattedReference;
        string _formattedAttention;

        public int? SnapshotId { get; set; }

        public int AccountDebtorId { get; set; }
        
        public int? AddressId { get; set; }

        public int? AttentionNameId { get; set; }

        public int? AddressChangeReasonId { get; set; }
        
        public string FormattedName
        {
            get => _formattedName;
            set => _formattedName = value.NullIfEmptyOrWhitespace();
        }

        public string FormattedAddress
        {
            get => _formattedAddress;
            set => _formattedAddress = value.NullIfEmptyOrWhitespace();
        }

        public string FormattedAttention
        {
            get => _formattedAttention;
            set => _formattedAttention = value.NullIfEmptyOrWhitespace();
        }

        public string FormattedReference
        {
            get => _formattedReference;
            set => _formattedReference = value.NullIfEmptyOrWhitespace();
        }
    }
}
