/* Decrypt .pdf files using AES  

@author  K Mallaiah */


import java.io.FileOutputStream;
import java.io.FileInputStream;

import com.lowagie.text.pdf.PdfEncryptor;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfStamper;
import com.lowagie.text.pdf.PdfWriter;
import java.security.*;
import java.security.spec.*;
import java.security.interfaces.*;
import java.util.*;

import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;

import javax.crypto.Cipher;
import javax.crypto.spec.*;
import javax.crypto.*;
import javax.crypto.CipherInputStream;
import javax.crypto.CipherOutputStream;
import java.io.*;
import com.lowagie.text.pdf.*;
import com.lowagie.text.*;
import java.math.BigInteger;
import java.io.IOException;


class RSA_AES_decr 
{
public static final int AES_Key_Size = 128;

static Cipher pkCipher, aesCipher;
byte[] aesKey;
SecretKeySpec aeskeySpec;

public static void main(String[] args) throws Exception {
        String sourceDir;
        String keyFolder;
        String collegeCode;
        String destinationDir;
        String lastName="";
        File path;
        BufferedReader bf = new BufferedReader(new InputStreamReader(System.in));
        System.out.print("Give your Collge Code:");
        collegeCode = bf.readLine();
        System.out.print("Give source folder for encrypted files:");
        sourceDir= bf.readLine();
        System.out.print("Give destination folder for decrypted files:");
        destinationDir =  bf.readLine();
	
        System.out.print("Give source  folder for keys:");
        keyFolder = bf.readLine();
        path=new File(sourceDir);
        File files[];
        files=path.listFiles();
	RSA_AES_decr  secure = new RSA_AES_decr();
    	
//  decrypting .pdf files 

	secure.loadKey(new File(keyFolder+"/"+collegeCode+"aes.key"),keyFolder+"/"+collegeCode+"private.key");
        for(int i=0; i < files.length; i++)
      {
       System.out.println(files[i].getName());
       StringTokenizer st= new StringTokenizer( files[i].toString(),"/");
       while(st.hasMoreTokens())
       {
       lastName=st.nextToken();
       }
       st= new StringTokenizer( lastName,"_");
       
       String outFileName=st.nextToken();
	secure.decrypt(files[i], new File(destinationDir+"/"+outFileName+"_decrypted.pdf"));
      }
}

/**
* Constructor: creates ciphers
*/
public RSA_AES_decr() throws GeneralSecurityException {
    // create RSA public key cipher
    pkCipher = Cipher.getInstance("RSA");
    // create AES shared key cipher
    aesCipher = Cipher.getInstance("AES");
}



/**
* Decrypts an AES key from a file using an RSA private key
*/
public void loadKey(File in, String privateKeyFile) throws GeneralSecurityException, IOException {
            try {
					// Read Private Key.
				File filePrivateKey = new File(privateKeyFile);
				FileInputStream fis = new FileInputStream(privateKeyFile);
				byte[] encodedPrivateKey = new byte[(int) filePrivateKey.length()];
				fis.read(encodedPrivateKey);
				fis.close();
				
				KeyFactory keyFactory = KeyFactory.getInstance("RSA");
					
				PKCS8EncodedKeySpec privateKeySpec = new PKCS8EncodedKeySpec(
					encodedPrivateKey);
				PrivateKey pk = keyFactory.generatePrivate(privateKeySpec);
                
               // read AES key
               pkCipher.init(Cipher.DECRYPT_MODE, pk);
               aesKey = new byte[AES_Key_Size/8];
               CipherInputStream is = new CipherInputStream(new FileInputStream(in), pkCipher);
               is.read(aesKey);
               aeskeySpec = new SecretKeySpec(aesKey, "AES");     
            } catch (Exception e) {
			System.out.println("Error in Loading AES Key !");
		}

   }


/**
 * Decrypts and then copies the contents of a given file.
 */
public void decrypt(File in, File out) throws IOException, InvalidKeyException {
	try{
	
	    aesCipher.init(Cipher.DECRYPT_MODE, aeskeySpec);

	    CipherInputStream is = new CipherInputStream(new FileInputStream(in), aesCipher);
	    FileOutputStream os = new FileOutputStream(out);

		copy(is, os);
		is.close();
	    	os.close();
	
	} catch (Exception e) {
		System.out.println("Decryption Error !");
    	}
    
}

/**
 * Copies a stream.
 */
private void copy(InputStream is, OutputStream os) throws IOException {
    int i;
    byte[] b = new byte[1024];
    while((i=is.read(b))!=-1) {
        os.write(b, 0, i);
    }
}
}
