using System.IO;
using Inprotech.Infrastructure;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.Web.ExchangeIntegration
{
    public interface IExchangePairedInstanceRequestValidator
    {
        bool ValidateMailbox(int userId, string mailbox);

        bool ValidateFileExtension(Stream fs);
    }

    class ExchangePairedInstanceRequestValidator : IExchangePairedInstanceRequestValidator
    {
        readonly IUserPreferenceManager _preferenceManager;
        readonly IFileTypeChecker _fileTypeChecker;

        public ExchangePairedInstanceRequestValidator(IUserPreferenceManager preferenceManager, IFileTypeChecker fileTypeChecker)
        {
            _preferenceManager = preferenceManager;
            _fileTypeChecker = fileTypeChecker;
        }

        public bool ValidateMailbox(int userId, string mailbox)
        {
            var preference = _preferenceManager.GetPreference<string>(userId, KnownSettingIds.ExchangeMailbox);
            return mailbox == preference;
        }

        public bool ValidateFileExtension(Stream fs)
        {
            var extractedExtn = _fileTypeChecker.GetFileType(fs).Extension;
            return extractedExtn != FileTypeExtension.WindowsDosExecutableFile;
        }
    }
}