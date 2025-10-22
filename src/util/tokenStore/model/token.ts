import config from '../../../config/config.js';
import mongoose from '../../db/mongodb/db.js';

const Token =
  config.tokenStoreType === 'mongodb'
    ? mongoose.model(
        'Token',
        new mongoose.Schema({
          WABrowserId: String,
          WASecretBundle: String,
          WAToken1: String,
          WAToken2: String,
          webhook: String,
          config: String,
          sessionName: String,
        })
      )
    : null;

export default Token;
