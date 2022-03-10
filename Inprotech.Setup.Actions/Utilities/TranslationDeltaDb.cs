using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;

namespace Inprotech.Setup.Actions.Utilities
{
    public interface ITranslationDeltaDb
    {
        IEnumerable<TranslationDeltaDb.TranslationDelta> GetTranslationDelta(string connectionString);
        Task UpdateTranslationDelta(string connectionString, string culture, string deltaContent);
        Task<int> InsertTranslationDelta(string connectionString, string culture, string deltaContent);
    }
    public class TranslationDeltaDb : ITranslationDeltaDb
    {
        public IEnumerable<TranslationDelta> GetTranslationDelta(string connectionString)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = "IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = \'TranslationDelta\') BEGIN select * from TranslationDelta END";

                var reader = command.ExecuteReader();
                while (reader.Read())
                {
                    yield return new TranslationDelta(reader.GetString(0), reader.GetString(2));
                }
            }
        }

        public async Task UpdateTranslationDelta(string connectionString, string culture, string deltaContent)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = "update TranslationDelta set Delta=@pDelta,LastModified=GETDATE() where Culture=@pCulture";

                var p1 = command.Parameters.Add("@pDelta", SqlDbType.NVarChar);
                var p2 = command.Parameters.Add("@pCulture", SqlDbType.NVarChar, 50);
                p1.Value = string.IsNullOrWhiteSpace(deltaContent)
                    ? DBNull.Value
                    : (object)deltaContent;

                p2.Value = culture;

                await command.ExecuteNonQueryAsync();
            }
        }

        public async Task<int> InsertTranslationDelta(string connectionString, string culture, string deltaContent)
        {
            using (var connection = new SqlConnection(connectionString))
            {
                connection.Open();
                var command = connection.CreateCommand();
                command.CommandText = "IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = \'TranslationDelta\') BEGIN BEGIN IF NOT EXISTS (SELECT * FROM TranslationDelta WHERE Culture = @pCulture) BEGIN INSERT INTO TranslationDelta VALUES (@pCulture, GETDATE(), @pDelta) END END END";

                var p1 = command.Parameters.Add("@pDelta", SqlDbType.NVarChar);
                var p2 = command.Parameters.Add("@pCulture", SqlDbType.NVarChar, 50);
                p1.Value = string.IsNullOrWhiteSpace(deltaContent)
                    ? DBNull.Value
                    : (object)deltaContent;

                p2.Value = culture;

                return await command.ExecuteNonQueryAsync();
            }
        }

        public class TranslationDelta
        {
            public TranslationDelta(string culture, string delta)
            {
                Culture = culture;
                Delta = delta;
            }

            public string Culture { get; set; }
            public string Delta { get; set; }
        }
    }
}