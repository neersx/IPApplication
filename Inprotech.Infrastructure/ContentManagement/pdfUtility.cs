using System;
using System.IO;
using Aspose.Pdf.Facades;
using Inprotech.Contracts;

namespace Inprotech.Infrastructure.ContentManagement
{
    public interface IPdfUtility
    {
        void Protect(Stream input);
        bool Concatenate(string[] files, string resultFileName, out Exception exception);
    }

    public class PdfUtility : IPdfUtility
    {
        internal class AdobeProfessional
        {
            internal static class ChangeAllowedSettings
            {
                internal const int NoChangesAllowed = 0;
            }

            internal static class PrintAllowedSettings
            {
                internal const int HighResolution = 2;
            }
        }
        
        public void Protect(Stream input)
        {
            if (input == null) throw new ArgumentNullException(nameof(input));

            var documentPrivilege = DocumentPrivilege.ForbidAll;

            documentPrivilege.AllowPrint = true;
            documentPrivilege.AllowCopy = true;

            documentPrivilege.ChangeAllowLevel = AdobeProfessional.ChangeAllowedSettings.NoChangesAllowed;
            documentPrivilege.PrintAllowLevel = AdobeProfessional.PrintAllowedSettings.HighResolution;
            
            using var secured = new PdfFileSecurity();
            
            input.Position = 0;

            secured.BindPdf(input);
            secured.EncryptFile(null, null, documentPrivilege, KeySize.x256, Algorithm.AES);
            secured.SetPrivilege(documentPrivilege);
            secured.Save(input);
        }

        public bool Concatenate(string[] files, string resultFileName, out Exception exception)
        {
            if (files == null) throw new ArgumentNullException(nameof(files));
            if (resultFileName == null) throw new ArgumentNullException(nameof(resultFileName));

            var editor = new PdfFileEditor();

            if (!editor.Concatenate(files, resultFileName))
            {
                exception = editor.LastException;
                return false;
            }

            exception = null;
            return true;
        }
    }
}
