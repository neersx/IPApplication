using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Inprotech.Integration.Artifacts;

namespace Inprotech.Integration.Documents
{
    public static class DocumentAndCaseExtensions
    {
        public static IQueryable<Document> For(this IQueryable<Document> documents, DataDownload dataDownload)
        {
            var applicationNumber = dataDownload.Case == null ? null : dataDownload.Case.ApplicationNumber;
            var registrationNumber = dataDownload.Case == null ? null : dataDownload.Case.RegistrationNumber;
            var publicationNumber = dataDownload.Case == null ? null : dataDownload.Case.PublicationNumber;

            return documents.For(applicationNumber, registrationNumber, publicationNumber)
                            .Where(_ => _.Source == dataDownload.DataSourceType);
        }

        public static IQueryable<Document> For(this IQueryable<Document> documents, string applicationNumber,
            string registrationNumber, string publicationNumber)
        {
            var a = Prepare(applicationNumber);
            var r = Prepare(registrationNumber);
            var p = Prepare(publicationNumber);

            return documents.Where
                (
                    _ =>
                        (_.ApplicationNumber != null && a.Contains(_.ApplicationNumber)) ||
                        (_.RegistrationNumber != null && r.Contains(_.RegistrationNumber)) ||
                        (_.PublicationNumber != null && p.Contains(_.PublicationNumber))
                );
        }

        public static IQueryable<Case> For(this IQueryable<Case> cases, Document document)
        {
            var applicationNumber = document == null ? null : document.ApplicationNumber;
            var registrationNumber = document == null ? null : document.RegistrationNumber;
            var publicationNumber = document == null ? null : document.PublicationNumber;

            return cases.For(applicationNumber, registrationNumber, publicationNumber)
                            .Where(_ => _.Source == document.Source);
        }

        public static IQueryable<Case> For(this IQueryable<Case> cases, string applicationNumber, string registrationNumber,
            string publicationNumber)
        {
            var a = Prepare(applicationNumber);
            var r = Prepare(registrationNumber);
            var p = Prepare(publicationNumber);

            return cases.Where
                (
                    _ =>
                        (_.ApplicationNumber != null && a.Contains(_.ApplicationNumber)) ||
                        (_.RegistrationNumber != null && r.Contains(_.RegistrationNumber)) ||
                        (_.PublicationNumber != null && p.Contains(_.PublicationNumber))
                );
        }

        static IEnumerable<string> Prepare(string n)
        {
            if (string.IsNullOrWhiteSpace(n)) yield break;

            yield return n;

            var n2 = StripNonAlphaNumerics(n);
            if (n2 != n && !string.IsNullOrWhiteSpace(n2))
                yield return n2;
        }

        static string StripNonAlphaNumerics(string input)
        {
            return string.IsNullOrWhiteSpace(input)
                ? input
                : Regex.Replace(input, "[^a-zA-Z0-9]", string.Empty, RegexOptions.Compiled);
        }
    }
}