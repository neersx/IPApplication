using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.System.Utilities
{
    [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "PlainText")]
    public interface IHtmlAsPlainText
    {
        string Retrieve(string htmlString);
    }

    [SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "PlainText")]
    public class HtmlAsPlainText : IHtmlAsPlainText
    {
        const string StripHtmlFunction = "dbo.fn_StripHTML";

        readonly IDbArtifacts _dbArtifacts;
        readonly IDbContext _dbContext;

        public HtmlAsPlainText(IDbArtifacts dbArtifacts, IDbContext dbContext)
        {
            if (dbArtifacts == null) throw new ArgumentNullException("dbArtifacts");
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _dbArtifacts = dbArtifacts;
            _dbContext = dbContext;
        }

        public string Retrieve(string htmlString)
        {
            if (!_dbArtifacts.Exists(StripHtmlFunction, SysObjects.Function) || string.IsNullOrWhiteSpace(htmlString))
            {
                return htmlString;
            }

            var command = _dbContext.CreateSqlCommand($"SELECT {StripHtmlFunction} (@p1)", new Dictionary<string, object> {{"p1", htmlString}});
            return command.ExecuteScalar() as string;
        }
    }
}