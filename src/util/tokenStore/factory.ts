import config from '../../config/config.js';
import FileTokenStore from './fileTokenStory.js';
import MongodbTokenStore from './mongodbTokenStory.js';
import RedisTokenStore from './redisTokenStory.js';

class Factory {
  public createTokenStory(client: any) {
    let myTokenStore;
    const type = config.tokenStoreType;

    if (type === 'mongodb') {
      myTokenStore = new MongodbTokenStore(client);
    } else if (type === 'redis') {
      myTokenStore = new RedisTokenStore(client);
    } else {
      myTokenStore = new FileTokenStore(client);
    }

    return myTokenStore.tokenStore;
  }
}

export default Factory;
