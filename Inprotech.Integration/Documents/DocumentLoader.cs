using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Integration.Persistence;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Integration.Documents
{
    public interface IDocumentLoader
    {
        IEnumerable<Document> GetDocumentsFrom(DataSourceType sourceType, int? caseId);
        int CountDocumentsFromSource(DataSourceType sourcetType);
        IEnumerable<Guid?> GetImportedRefs(int? caseId);
    }

    public class DocumentLoader : IDocumentLoader
    {
        readonly IRepository _repository;
        readonly IDbContext _dbContext;

        public DocumentLoader(IRepository repository, IDbContext dbContext)
        {
            if (repository == null) throw new ArgumentNullException("repository");
            if (dbContext == null) throw new ArgumentNullException("dbContext");
            _repository = repository;
            _dbContext = dbContext;
        }

        public IEnumerable<Document> GetDocumentsFrom(DataSourceType sourceType, int? caseId)
        {
            var numbers = ExtractCurrentNumbers(caseId);

            return _repository.Set<Document>()
                .Include(_ => _.DocumentEvent)
                .Where(
                    d => (d.Status != DocumentDownloadStatus.Pending)
                         && d.Source == sourceType
                         && (
                             (d.ApplicationNumber != null && numbers.A.Contains(d.ApplicationNumber)) ||
                             (d.RegistrationNumber != null && numbers.R.Contains(d.RegistrationNumber)) ||
                             (d.PublicationNumber != null && numbers.P.Contains(d.PublicationNumber))
                             ));
        }

        public int CountDocumentsFromSource(DataSourceType dataSource)
        {
            return _repository
                .Set<Document>()
                .Count(
                    d =>
                        d.Source == dataSource &&
                        d.Status == DocumentDownloadStatus.Downloaded);
        }

        public IEnumerable<Guid?> GetImportedRefs(int? caseId)
        {
            return _dbContext.Set<InprotechKaizen.Model.Cases.Case>()
                .Single(c => c.Id == caseId)
                .Activities
                .SelectMany(a => a.Attachments)
                .Where(a => a.Reference != null)
                .Select(a => a.Reference);
        }

        CurrentNumbers ExtractCurrentNumbers(int? caseId)
        {
            var numbers = _dbContext.Set<OfficialNumber>()
                .Where(
                    n => n.CaseId == caseId
                         && n.IsCurrent == 1)
                .Select(_ => new { Type = _.NumberTypeId, _.Number })
                .ToList();

            return new CurrentNumbers
            {
                A = From(numbers, KnownNumberTypes.Application),
                R = From(numbers, KnownNumberTypes.Registration),
                P = From(numbers, KnownNumberTypes.Publication)
            };
        }

        static string[] From(IEnumerable<dynamic> numbers, string numberType)
        {
            var n = numbers.SingleOrDefault(_ => _.Type == numberType);

            return n == null
                ? new string[0]
                : new string[]
                {
                    n.Number,
                    StripNonAlphaNumerics(n.Number)
                };
        }

        static string StripNonAlphaNumerics(string input)
        {
            return string.IsNullOrWhiteSpace(input) ? input : Regex.Replace(input, "[^a-zA-Z0-9]", string.Empty, RegexOptions.Compiled);
        }

        public class CurrentNumbers
        {
            public string[] A { get; set; }
            public string[] R { get; set; }
            public string[] P { get; set; }
        }
    }
}